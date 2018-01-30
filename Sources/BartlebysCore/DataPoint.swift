//
//  DataPoint.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

#if USE_BTREE
#if !USE_EMBEDDED_MODULES
    import BTree
#endif
    fileprivate typealias _ContainerType = Map
#else
    fileprivate typealias _ContainerType = Dictionary
#endif


public enum DataPointError : Error{
    case invalidURL
    case voidURLRequest
    case payloadIsNil
    case payloadShouldBeOfFilePathType
    case duplicatedRegistration(fileName:String)
    case instanceNotFound
    case instanceTypeMissMatch
    case callOperationCollectionNotFound(named:String)
    case callOperationIndexNotFound(named:String)
    case multipleProvisioningAttempt(of:CallOperationProtocol)
}

public protocol DataPointLifeCycle{
    func collectionsDidLoadSuccessFully(dataPoint:DataPointProtocol)
    func collectionsDidFailToLoad(dataPoint:DataPointProtocol ,message:String)
    func collectionsDidSaveSuccessFully(dataPoint:DataPointProtocol)
    func collectionsDidFailToSave(dataPoint:DataPointProtocol,message:String)
}

// Abstract class
open class DataPoint: Object,DataPointProtocol{
    
    // KVS keys
    static public let sessionLastExecutionKVSKey = "sessionLastExecutionKVSKey"
    static public let noContainerRootKey = "noContainerRootKey"
    
    public enum RelativePaths:String{
        case forCallOperations = "operations/"
        case forCollections = ""
    }
    
    // MARK: -
    
    public var delegate: DataPointLifeCycle?
    
    // The coder used by the HTTP operations.
    public var operationsCoder: ConcreteCoder = JSONCoder()
    
    // The storage IO object: reads an writes the ObjectsCollections
    public var storage:StorageProtocol = FileStorage()
    
    /// The associated session
    public lazy fileprivate(set) var session:Session = Session(delegate: self, lastExecutionOrder:self._getLastOrderOfExecution())
    
    /// Its session identifier
    public var sessionIdentifier: String {
        get{
            return self.session.identifier
        }
        set{
            self.session.identifier = newValue
        }
    }
    
    /// Contains all the data Point collections
    /// Populated by registerCollection
    /// - Returns: the data Point model collections
    fileprivate var _collections:[FileSavable] = [FileSavable]()
    
    /// The collection hashed per fileNam
    fileprivate var _collectionsPerFileName = [String:FileSavable]()
    
    /// The collection hashed by typeName
    fileprivate var _collectionsPerCollectedTypeName = [String:FileSavable]()
    
    // this centralized dictionary allows to access to any referenced object by its UID
    // Uses a binary tree
    fileprivate var _instancesByUID=_ContainerType<UID,Any>()
    
    /// Defered Ownership
    /// If we receive a Instance that refers to an unexisting Owner
    /// We store its missing entry is the deferredOwnerships dictionary
    /// For future resolution (on registration)
    /// [notAvailableOwnerUID][relatedOwnedUIDS]
    fileprivate var _deferredOwnerships=[UID:[UID]]()
    
    /// The pending Call operations
    fileprivate var _sortedPendingCalls:[CallSequence.Name:[CallOperationProtocol]] = [CallSequence.Name:[CallOperationProtocol]]()
    
    
    /// The current number of Pending calls
    public var numberOfPendingCalls:Int{
        var n = 0
        for (_,c) in self._sortedPendingCalls{
            n += c.count
        }
        return n
    }
    
    /// The planified future works
    fileprivate var _futureWorks:[CallSequence.Name:[AsyncWork]] = [CallSequence.Name:[AsyncWork]]()
    
    // MARK: -
    
    /// A collection used to perform Key Value Storage
    public var keyedDataCollection = CollectionOf<KeyedData>(named:KeyedData.collectionName,relativePath:"")
    
    // Special call Operations Donwloads and Uploads
    public var downloads = CollectionOf<CallOperation<FilePath,Download>>()
    public var uploads = CollectionOf<CallOperation<FilePath,Upload>>()
    
    
    /// Initializes the dataPoint
    /// - Throws: Children may throw while populating the collections
    required public override init(){
        super.init()
        // The loading is asynchronous on separate queue.
        self.storage.addProgressObserver (observer: AutoRemovableLoadingDelegate(dataPoint: self))
    }
    
    // MARK: - OperatingState
    
    // The current Operating state
    public fileprivate(set) var currentState:OperatingState = .online
    
    /// Used to transition offline on online
    ///
    /// - Parameter state: the new operating state
    public func transition(to newState:OperatingState){
        guard newState != self.currentState else{
            return
        }
        self.currentState = newState
        self.session.applyState()
        switch newState{
        case .online:
            // Resume
            for sequ in self._sortedPendingCalls.keys{
                self._sortedPendingCalls[sequ]?.first?.execute()
            }
        case .offline:
            // Cancel futures calls.
            for sequ in self._futureWorks.keys{
                self._futureWorks[sequ]?.first?.cancel()
            }
        }
    }
    
    
    // MARK: -
    
    /// Prepares the collections before loading the data in memory.
    /// That the place where you should call :
    ///
    /// try self.registerCollection(collection:concreteCollection)
    /// and
    /// try self.registerCallOperationsFor(type: Metrics.self)
    ///
    /// - Parameter volatile: If set to true the storage will be in memory You cannot turn back storage volatility to false
    ///                       This mode allows to create temporary in Memory DataPoint to be processed and merged in persistent dataPoints
    /// - Throws: errors on registration
    open func prepareCollections(volatile: Bool) throws {
        Logger.log("\(String(describing: type(of: self))) - \(getElapsedTime())", category: .standard)
        Logger.log("----", category:.standard,decorative:true)
        if volatile {
            self.storage.becomeVolatile()
        }
        do{
            // The KVS collection is loaded synchronously and saved asynchronouly
            let loadedKeyedDataCollection:CollectionOf<KeyedData> = try self.storage.loadSync(fileName: self.keyedDataCollection.fileName, relativeFolderPath: self.keyedDataCollection.relativeFolderPath)
            self.keyedDataCollection = loadedKeyedDataCollection
        }catch FileStorageError.notFound{
            // It may be the first time don't panic
        }catch{
            Logger.log("\(error)", category: .critical)
        }
        
        self._configureCollection(self.keyedDataCollection)
        
        // Special Call Operations (Downloads and Uploads)
        try self.registerCollection(collection: self.downloads)
        try self.registerCollection(collection: self.uploads)
        
        // Generated Models
        try self.registerCallOperationsFor(type: Metrics.self)
        try self.registerCallOperationsFor(type: KeyedData.self)
        try self.registerCallOperationsFor(type: LogEntry.self)
    }
    
    
    /// Registers the CallOperations collections
    /// that provision the call for Off line support & fault tolerence
    ///
    /// - Parameter type: the call Payload and resultType
    /// - Throws: erros on collection registration.
    open func registerCallOperationsFor<T:Payload & Result & Collectable>(type:T.Type) throws {
        //self._callOperationsTypes.append(type)
        let upStreamOperations = CallOperation<T,VoidResult>.registrableCollection
        let downStreamOperations = CallOperation<VoidPayload,T>.registrableCollection
        try self.registerCollection(collection: upStreamOperations)
        try self.registerCollection(collection: downStreamOperations)
    }
    
    
    /// Registers the collection into the data point
    ///
    /// - Parameter collection: the collection
    open func registerCollection<T>(collection:CollectionOf<T>)throws{
        if !self._collections.contains(where: { (existingCollection) -> Bool in
            if let c = existingCollection as? CollectionOf<T>{
                // @todo to be removed
                return c.d_collectionName == collection.d_collectionName && c.fileName == collection.fileName
            }
            return false
        }){
            self._configureCollection(collection)
            // Creates or asynchronously load the collection on registration
            try self.storage.loadCollection(on: collection)
            
        }else{
            throw DataPointError.duplicatedRegistration(fileName: collection.fileName)
        }
    }
    
    fileprivate func _configureCollection<T>(_ collection:CollectionOf<T>){
        // Reference the DataPoint
        collection.dataPoint = self
        self._collections.append(collection)
        self._collectionsPerFileName[collection.fileName] = collection
        self._collectionsPerCollectedTypeName[T.typeName] = collection
    }
    
    /// Returns the collection by its file name
    ///
    /// - Parameter fileName: the fileName of the searched collection
    /// - Returns: the CollectionOf
    public func collection<T>(with fileName:String)->CollectionOf<T>?{
        return self._collectionsPerFileName[fileName] as? CollectionOf<T>
    }
    
    
    public func collectionsCount() -> Int {
        return self._collections.count
    }
    
    
    // MARK: - DataPointProtocol
    
    // The current Host: e.g demo.bartlebys.org
    open var host: String = "NO_HOST"
    
    // The api base path: e.g /api/v1
    open var apiBasePath: String = "NO_BASE_API_PATH"
    
    // MARK: -  SessionDelegate
    
    /// The credentials should generaly not change during the session
    open var credentials: Credentials = Credentials(username: Default.NO_NAME, password: Default.NO_PASSWORD)
    
    /// The authentication method
    open var authenticationMethod: AuthenticationMethod = AuthenticationMethod.basicHTTPAuth
    
    /// The current Scheme .https is a must
    open var scheme: Schemes = Schemes.https
    
    ///  Returns the configured URLrequest
    ///  This func is public not open
    /// - Parameters:
    ///   - path: the path e.g: users/
    ///   - queryString: eg: &page=0&size=10
    ///   - method: the http Method
    /// - Returns:  the URL request
    /// - Throws: url issues
    open func requestFor(path: String, queryString: String, method: HTTPMethod) throws -> URLRequest {
        
        guard let url = URL(string: self.scheme.rawValue + self.host + path + queryString) else {
            throw DataPointError.invalidURL
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        switch self.authenticationMethod {
        case .basicHTTPAuth:
            let loginString = "\(self.credentials.username):\(self.credentials.password)"
            if let loginData: Data = loginString.data(using: .utf8) {
                let base64LoginString: String = loginData.base64EncodedString()
                request.setValue(base64LoginString, forHTTPHeaderField: "Authorization")
            }
        }
        
        return request
    }
    
    
    /// Returns the configured URLrequest
    ///
    /// - Parameters:
    ///   - path: the path e.g: users/
    ///   - queryString: eg: &page=0&size=10
    ///   - method: the http Method
    /// - Returns: the URL request
    /// - Throws: issue on URL creation or Parameters deserialization
    public final func requestFor<P:Payload>(path: String, queryString: String, method: HTTPMethod , parameter:P) throws -> URLRequest {
        
        var request = try self.requestFor(path: path, queryString: queryString, method: method)
        
        if !(parameter is VoidPayload) && !(parameter is FilePath) {
            // By default we encode the JSON parameter in the body
            // If the Parameter is not void
            request.httpBody = try JSONEncoder().encode(parameter)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    
    /// Provisions the operation in the relevent collection
    /// If the collection exceeds the preservationQuota destroys the first entries
    ///
    /// - Parameter operation: the call operation
    /// - Throws: error if the collection hasn't be found
    public func provision<P, R>(_ operation:CallOperation<P, R>) throws{
        
        // Upsert the relevent call Operation collection
        guard let collection = self._collectionsPerCollectedTypeName[CallOperation<P, R>.typeName] as? CollectionOf<CallOperation<P, R>> else{
            throw DataPointError.callOperationCollectionNotFound(named: CollectionOf<CallOperation<P, R>>.collectionName)
        }
        
        // Store the call operation into the relevent collection
        collection.upsert(operation)
        try self._addToPendingCalls(operation)
        try self._applyQuotaOn(collection)

    }


    fileprivate func _addToPendingCalls<P,R>(_ operation:CallOperation<P, R>) throws {
        // Append the call operation to the pending Calls
        if !self._sortedPendingCalls.keys.contains(operation.sequenceName){
            self._sortedPendingCalls[operation.sequenceName] = [CallOperationProtocol]()
        }
        if (self._sortedPendingCalls[operation.sequenceName]?.index(where: { return $0.uid == operation.uid }) != nil){
            throw DataPointError.multipleProvisioningAttempt(of:operation)
        }else{
            self._sortedPendingCalls[operation.sequenceName]?.append(operation)
        }
    }

    fileprivate func _applyQuotaOn<P,R>(_ collectionOfCallOperations:CollectionOf<CallOperation<P, R>> ) throws {
        // Preservation Quotas.
        let maxOperations = self.preservationQuota(callOperationType:CallOperation<P, R>.self)
        if maxOperations < collectionOfCallOperations.count{
            // We should destroy some operations
            let nbOfOperationToDestroy = collectionOfCallOperations.count - maxOperations
            Logger.log("Destroying \(nbOfOperationToDestroy) operation(s) from \(collectionOfCallOperations.d_collectionName)", category: .standard)
            for _ in 0..<nbOfOperationToDestroy{
                collectionOfCallOperations.remove(at: 0)
            }
        }
    }

    
    
    /// Returns the relevent request for a given call Operation
    ///
    /// - Parameter operation: the operation
    /// - Returns: the URL request
    /// - Throws: issue on URL creation and operation Parameters serialization
    public final func requestFor<P, R>(_ operation: CallOperation<P, R>) throws -> URLRequest {
        
        if R.self is Download.Type || R.self is Upload.Type {
            guard let payload = operation.payload else {
                throw DataPointError.payloadIsNil
            }
            guard (P.self is FilePath.Type) else {
                throw DataPointError.payloadShouldBeOfFilePathType
            }
            // Return the Download or Upload base request
            return try self.requestFor(path: operation.path, queryString: operation.queryString, method: operation.method, parameter: payload)
        }
        
        if let payload = operation.payload {
            // There is a payload
            return try self.requestFor(path: operation.path, queryString: operation.queryString, method: operation.method, parameter: payload)
        }else{
            // The payload is void
            return try self.requestFor(path: operation.path, queryString: operation.queryString, method: operation.method)
        }
    }
    
    
    // MARK: - Data integration and Operation Life Cycle
    
    /// The response.result shoud be stored in it DataPoint storage layer
    ///
    /// - Parameter response: the call Response
    public final func integrateResponse<R>(_ response: DataResponse<R>) {
        if let firstCollection = self._collections.first(where:{ $0 as? CollectionOf<R> != nil }) {
            if let concreteCollection = firstCollection as? CollectionOf<R>{
                for instance in response.result {
                    concreteCollection.upsert(instance)
                }
            }
        }
    }
    
    /// Implements the  Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    public final func deleteCallOperation<P, R>(_ operation: CallOperation<P, R>)throws{
        
        self._cleanUpFutureWorks(operation)
        
        // Sorted pending calls.
        if let index = self._sortedPendingCalls[operation.sequenceName]?.index(where: { $0.uid == operation.uid} ){
            self._sortedPendingCalls[operation.sequenceName]?.remove(at: index)
        }else {
            throw DataPointError.callOperationIndexNotFound(named: operation.operationName)
        }
        
    }
    /// Implements Called on success
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - error: the error
    public func callOperationExecutionDidSucceed<P, R>(_ operation: CallOperation<P, R>) throws{

        defer{
            let notificationName = Notification.Name.CallOperation.didSucceed()
            var userInfo :[AnyHashable : Any] = [Notification.Name.CallOperation.operationKey : operation]
            if let filePath = operation.payload as? FilePath {
                userInfo[Notification.Name.CallOperation.filePathKey] = filePath
            }
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo:userInfo)
        }


        operation.hasBeenExecuted()
        try self.deleteCallOperation(operation)
        self._executeNextCallOperation(from: operation.sequenceName)

    }


    /// Implements the faulting logic
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - error: the error
    public final func callOperationExecutionDidFail<P, R>(_ operation: CallOperation<P, R>, error:Error?) throws {

        defer{
            // Send a notification
            let notificationName = Notification.Name.CallOperation.didFail()
            if let error = error {
                // Can be a FileOperationError with associated FilePath
                NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [Notification.Name.CallOperation.operationKey : operation, Notification.Name.CallOperation.errorKey : error])
            } else {
                NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [Notification.Name.CallOperation.operationKey : operation])
            }
        }

        operation.hasBeenExecuted()

        let sequenceName : CallSequence.Name = operation.sequenceName
        self._cleanUpFutureWorks(operation)

        // Should we detroy the operation on Failure?
        // Or try to rexecute later.
        if operation.isBlocked{
            // Blocked
            if operation.isDestroyableWhenBlocked{
                // The operation is blocked and destroyable.
                // Let's delete it.
                Logger.log("Deleting \(operation.operationName) \(operation.uid) ", category: .standard)
                try self.deleteCallOperation(operation)
                /// And then execute the next in the Call Sequence
                self._executeNextCallOperation(from: sequenceName)
            }else{
                // Blocked & Not Destroyable
                // The operation is Blocked
                // All the CallSequence is stuck
            }
        }else{
            // The Operation is not blocked
            // It means we can try to re-implement the running logic
            if self.currentState == .online{
                // Re-execution logic
                //We double the reExecutionDelay (may be we should use another strategy)
                operation.reExecutionDelay = operation.reExecutionDelay * 2
                
                let workItem = DispatchWorkItem.init {
                    operation.execute()
                }
                let delay:TimeInterval = operation.reExecutionDelay
                
                let work = AsyncWork(dispatchWorkItem: workItem, delay: delay, associatedUID:operation.uid)
                if !self._futureWorks.keys.contains(operation.sequenceName){
                    self._futureWorks[operation.sequenceName] = [AsyncWork]()
                }
                self._futureWorks[operation.sequenceName]?.append(work)
            }else{
                // We are not running live
                // So there is no reason to create an AsyncWork
            }
        }
    }
    
    fileprivate func _cleanUpFutureWorks<P, R>(_ operation: CallOperation<P, R>){
        // CleanUp the future works
        if let index = self._futureWorks[operation.sequenceName]?.index(where: {$0.associatedUID == operation.uid}){
            self._futureWorks[operation.sequenceName]?.remove(at: index)
        }
    }
    
    
    fileprivate func _futureWorksArePlanifiedFor(_ callSequenceName:CallSequence.Name)->Bool{
        guard let futuresWorks = self._futureWorks[callSequenceName] else{
            return false
        }
        return futuresWorks.count > 0
    }
    
    /// Executes the next Pending Operations for a given the CallSequence Name
    /// The call sequences are runing in parallel.
    /// Called on success by the session or on failure in the DataPoint if the Operation is Blocked and Destroyable
    ///
    /// - Parameter callSequenceName: the Call sequence name
    fileprivate func _executeNextCallOperation(from callSequenceName:CallSequence.Name){
        // 1) we don't want to execute tasks if the session is not running live
        // 2) We want to execute sequentially the items segmented per CallSequence
        if self.currentState == .online && !self._futureWorksArePlanifiedFor(callSequenceName){
            self._sortedPendingCalls[callSequenceName]?.first?.execute()
        }
    }

    /// Used to determine if we should destroy some Operations
    /// Returns a quota of operation to preserve for each sequence.
    /// If the value is over the quota the older operations are destroyed
    /// By default Bartleby "would prefer not to" that's why the preservationQuota respond Int.max by defaults
    ///
    /// - Parameter for: the CallSequence name
    /// - Returns: the max number of call operations.
    open func preservationQuota<P,R>(callOperationType:CallOperation<P,R>.Type)->Int{
        // By default we keep all the call Operations
        // But you can ovveride this method to limit the size of a call operation collection
        return Int.max
    }





    // MARK: - Load and Save

    open func save() throws {

        // Store the state in KVS
        try self.storeInKVS(self.session.lastExecutionOrder, identifiedBy: DataPoint.sessionLastExecutionKVSKey)
        // The KVS is loaded synchronously and saved asynchronouly
        try self.storage.saveCollection(self.keyedDataCollection)

        // We add a saving delegate to relay the progression
        self.storage.addProgressObserver (observer: AutoRemovableSavingDelegate(dataPoint: self))
        for collection in self._collections {
            try collection.saveToFile()
        }
    }

    /// Called before erasure by ManagedModel.erase() of a managedModel Descendant
    /// You should override this method to perform for example associated files deletions...
    ///
    /// - Parameter instance: the managedModelx
    open func willErase(_ instance:Model){}




    /// Object factory that creates a new instance
    //  and append the object to the first Corresponding Collection
    ///
    /// - Returns: the created instance
    open func newInstance<T:Collectable & Codable  >()->T{
        let instance = T()
        if let collection:CollectionOf<T> = self.collectionFor() {
            collection.append(instance)
        }
        return instance
    }


    /// Object factory that creates a new instance
    //  and append the object to the first Corresponding Collection
    ///
    /// - Returns: the created instance
    open func new<T:Collectable & Codable >(type:T.Type)->T{
        let instance = T()
        if let collection:CollectionOf<T> = self.collectionFor() {
            collection.append(instance)
        }
        return instance
    }


    /// Recover a collection for a given Collectable type
    ///
    /// - Returns: the collection
    open func collectionFor<T:Collectable & Codable> ()->CollectionOf<T>?{
        return self._collectionsPerCollectedTypeName[T.typeName] as? CollectionOf<T>
    }


    // MARK: - DataPointProtocol.DataPointLifeCycle

    // The data point implements its own delegate
    /// That relays to its delegate

    public func collectionsDidLoadSuccessFully(dataPoint:DataPointProtocol){
        self.delegate?.collectionsDidLoadSuccessFully(dataPoint: dataPoint)
        self._recoverThePendingCallOperations()
    }

    public func collectionsDidFailToLoad(dataPoint:DataPointProtocol ,message:String){
        self.delegate?.collectionsDidFailToLoad(dataPoint: dataPoint, message: message)
    }

    public func collectionsDidSaveSuccessFully(dataPoint: DataPointProtocol) {
        self.delegate?.collectionsDidSaveSuccessFully(dataPoint: dataPoint)
    }

    public func collectionsDidFailToSave(dataPoint: DataPointProtocol, message: String) {
        self.delegate?.collectionsDidFailToSave(dataPoint: dataPoint, message: message)
    }

    /// Stores the call operation in _sortedPendingCalls
    /// Sorted by scheduledOrderOfExecution
    fileprivate func _recoverThePendingCallOperations(){
        for collection in self._collections{
            if let collection = collection as? IndistinctCollection{
                if let callOperations = collection.dynamicCallOperations{
                    if let firstElement = callOperations.first{
                        self._sortedPendingCalls[firstElement.sequenceName]?.append(contentsOf: callOperations)
                    }
                }
            }
        }
        for sequenceNamed in self._sortedPendingCalls.keys{
            self._sortedPendingCalls[sequenceNamed]?.sort { (lCalOp, rCalOp) -> Bool in
                return lCalOp.scheduledOrderOfExecution < rCalOp.scheduledOrderOfExecution
            }
        }
    }

}


// MARK: - Centralized Instances Registration

extension DataPoint{
    
    // The number of registred object
    public var numberOfRegistredObject: Int {
        get {
            return self._instancesByUID.count
        }
    }
    
    /// Registers an instance
    ///
    /// - Parameter instance: the instance to be registered
    public func register<T:  Codable & Collectable >(_ instance: T) {
        // Store the instance by its UID
        self._instancesByUID[instance.id]=instance
        
        // Check if some deferred Ownership has been recorded
        if let owneesUIDS = self._deferredOwnerships[instance.id] {
            /// This situation occurs for example
            /// when the ownee has been triggered but not the owner
            // or the deserialization of the ownee preceeds the owner
            if let o=instance as? Model{
                for owneeUID in  owneesUIDS{
                    if let _ = self.registredModelByUID(owneeUID){
                        // Add the owns entry
                        if !o.owns.contains(owneeUID){
                            o.owns.append(owneeUID)
                        }else{
                            Swift.print("### !")
                        }
                    }else{
                        Logger.log("Deferred ownership has failed to found \(owneeUID) for \(o.id)", category: .critical)
                    }
                }
            }
            self._deferredOwnerships.removeValue(forKey: instance.id)
        }
    }
    
    
    /// Removes the registred instance from the registry
    ///
    /// - Parameter instance: the instance
    public func unRegister<T:  Codable & Collectable >(_ instance: T) {
        self._instancesByUID.removeValue(forKey: instance.id)
    }
    
    /// Removes the registred instances from the registry
    ///
    /// - Parameter instance: the instance
    public func unRegister<T:  Codable & Collectable >(_ instances: [T]) {
        for instance in instances{
            self.unRegister(instance)
        }
    }
    
    // MARK: Generic level
    
    /// Returns the registred instance of by its UID
    ///
    /// - Parameter UID: the instance unique identifier
    /// - Returns: the instance
    public func registredObjectByUID<T: Codable & Collectable>(_ UID: UID) throws-> T {
        if let instance=self._instancesByUID[UID]{
            if let casted=instance as? T{
                return casted
            }else{
                throw DataPointError.instanceTypeMissMatch
            }
        }else{
            throw DataPointError.instanceNotFound
        }
    }
    
    ///  Returns the registred instance of by UIDs
    ///
    /// - Parameter UIDs: the UIDs
    /// - Returns: the registred Instances
    public func registredObjectsByUIDs<T: Codable & Collectable >(_ UIDs: [UID]) throws-> [T] {
        var items:[T]=[T]()
        for UID in UIDs{
            if let instance=self._instancesByUID[UID]{
                if let casted=instance as? T{
                    items.append(casted)
                }else{
                    throw DataPointError.instanceTypeMissMatch
                }
            }else{
                throw DataPointError.instanceNotFound
            }
        }
        return items
    }
    
    // MARK: Model level
    
    /// Returns a Model by its UID
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectable>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredModelByUID(_ UID: UID)-> Model? {
        return try? self.registredObjectByUID(UID)
    }
    
    /// Returns a collection of Model by UIDs
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectable>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredModelByUIDs(_ UIDs: [UID])-> [Model]? {
        return try? self.registredObjectsByUIDs(UIDs)
    }
    
    
    // MARK: Opaque level
    
    /// Totaly opaque accessor
    ///
    /// - Parameter UID: the UID
    /// - Returns: the opaque Instance
    public func registredOpaqueInstanceByUID(_ UID: UID)-> Any? {
        return self._instancesByUID[UID]
    }
    
    /// Totaly opaque accessor
    ///
    /// - Parameter UID: the UID
    /// - Returns: the opaque Instance
    public func registredOpaqueInstancesByUIDs(_ UIDs: [UID])-> [Any] {
        var items:[Any]=[Any]()
        for UID in UIDs{
            if let instance=self._instancesByUID[UID]{
                items.append(instance)
            }
        }
        return items
    }
    
    // MARK: -
    
    /// Stores the ownee when the owner is not already available
    /// This situation may occur for example on collection deserialization
    /// when the owner is deserialized before the ownee.
    ///
    /// - Parameters:
    ///   - ownee: the ownee
    ///   - ownerUID: the currently unavailable owner UID
    public func appendToDeferredOwnershipsList<T:Codable & Collectable>(_ ownee:T,ownerUID:UID){
        if self._deferredOwnerships.keys.contains(ownerUID) {
            self._deferredOwnerships[ownerUID]?.append(ownee.id)
        }else{
            self._deferredOwnerships[ownerUID]=[ownee.id]
        }
    }
    
    
    // MARK: - Private plumbing
    
    fileprivate func _getLastOrderOfExecution()->Int{
        do{
            if let order:Int = try self.getFromKVS(key: DataPoint.sessionLastExecutionKVSKey){
                return order
            }
        }catch KeyValueStorageError.keyNotFound{
            // it may be the first time
        }catch{
            // That's not normal
            Logger.log("\(error)", category: .critical)
        }
        return ORDER_OF_EXECUTION_UNDEFINED
    }
}

// MARK: - Download / Uploads

extension DataPoint{
    
    public func cancelUploads(){
        self.downloads.removeAll()
    }
    public func cancelDownloads(){
        self.uploads.removeAll()
    }
}
