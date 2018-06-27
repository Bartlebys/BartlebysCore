//
//  DataPoint.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

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

enum SessionError : Error {
    case deserializationFailed
    case fileNotFound
    case multipleExecutionAttempts
    case unProvisionedOperation
}


public protocol DataPointLifeCycle{
    func collectionsDidLoadSuccessFully(dataPoint:DataPointProtocol)
    func collectionsDidFailToLoad(dataPoint:DataPointProtocol ,message:String)
    func collectionsDidSaveSuccessFully(dataPoint:DataPointProtocol)
    func collectionsDidFailToSave(dataPoint:DataPointProtocol,message:String)
}


open class DataPoint: Object,DataPointProtocol{
    
    
    // KVS keys
    static public let sessionLastExecutionKVSKey = "sessionLastExecutionKVSKey"
    
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
    
    /// Its session identifier
    public var sessionIdentifier: String {
        get{
            return self.identifier
        }
        set{
            self.identifier = newValue
        }
    }

    // We multiply by 2 the delay betweeen each execution
    // This is the max re execution delay
    public var maxReexecutionDelayInSecond:TimeInterval = 60

    /// Contains all the data Point collections
    /// Populated by registerCollection
    /// - Returns: the data Point model collections
    fileprivate var _collections:[IndistinctCollection] = [IndistinctCollection]()
    
    /// The collection hashed per fileNam
    fileprivate var _collectionsByFileName = [String:IndistinctCollection]()

    // The collection by collection name
    fileprivate var _collectionsByName = [String:IndistinctCollection]()
    
    /// The collection hashed by typeName
    fileprivate var _collectionsByCollectedTypeName = [String:IndistinctCollection]()
    
    // this centralized dictionary allows to access to any referenced object by its UID
    // Uses a binary tree
    fileprivate var _instancesByUID = Dictionary<UID,Any>()
    
    /// Defered Ownership
    /// If we receive a Instance that refers to an unexisting Owner
    /// We store its missing entry is the deferredOwnerships dictionary
    /// For future resolution (on registration)
    /// [notAvailableOwnerUID][relatedOwnedUIDS]
    fileprivate var _deferredOwnerships=[UID:[UID]]()
    
    /// The pending Call operations
    fileprivate var _sortedPendingCalls:[CallSequence.Name:[CallOperationProtocol]] = [CallSequence.Name:[CallOperationProtocol]]()
    
    /// You can store CallSequence to characterize their behavior
    fileprivate var _callSequences = [CallSequence]()

    /// Counts all HTTP errors
    public internal(set) var errorCounter: Int = 0
    
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
    // The KVS collection is loaded synchronously and saved asynchronouly
    public lazy var keyedDataCollection = CollectionOf<KeyedData>(named:KeyedData.collectionName,relativePath:self.sessionIdentifier)
    
    // Special call Operations Donwloads and Uploads
    public let downloads = CollectionOf<CallOperation<FilePath,Download>>()
    public let uploads = CollectionOf<CallOperation<FilePath,Upload>>()
    public let simpleQueries = CollectionOf<CallOperation<VoidPayload,VoidResult>>() // usable for simple Query string encoded calls on any method.


    // A shared void Payload instance
    public static let voidPayload = VoidPayload()

    // The session Identifier
    public var identifier: String = Default.NO_UID{
        didSet{
            if oldValue != Default.NO_UID {
                Logger.log("The Session identifier has been reset, old identifier:\(oldValue) new identifier: \(identifier) ", category: .warning)
            }
        }
    }

    // the last executionOrder
    public fileprivate(set) var lastExecutionOrder:Int = ORDER_OF_EXECUTION_UNDEFINED

    // A unique run identifier that changes on each launch
    public static let runUID: String = Utilities.createUID()

    // Background operation co
    public var allowBackgroundOperations: Bool = true

    /// Determine if the call are operated when the app is in Background mode.
    public fileprivate(set) var isRunningInBackGround: Bool = false

    // We store the running call operations UIDS
    public fileprivate(set) var runningCallsUIDS = [UID]()

    /// The absolutat current time on instantiation
    public let startTime = AbsoluteTimeGetCurrent()

    /// The elapsed time from start.
    public var elapsedTime:Double {
        return AbsoluteTimeGetCurrent() - self.startTime
    }

    public func infos() -> String {
        return "v1.1.0"
    }


    
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
        switch newState{
        case .online:
           self._resumeCallSequences()
        case .offline:
            // Cancel futures calls.
            for sequ in self._futureWorks.keys{
                if let works = self._futureWorks[sequ]{
                    for work in works{
                        work.cancel()
                    }
                }
            }
        }
    }

    /// Runs only one call operation per call sequence
    /// The call operations are not chained anymore.
    public func didEnterBackground(){
        self.isRunningInBackGround = true
    }

    /// Return to chained call sequence mode.
    public func willEnterForeground(){
        self.isRunningInBackGround = false
        if !self.allowBackgroundOperations{
            self._resumeCallSequences()
        }

    }


    fileprivate func _resumeCallSequences(){
        // Resume
        for callSequence in self._callSequences{
            self.executeNextBunchOfCallOperations(from: callSequence.name)
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
            if !volatile{
                // The KVS collection is loaded synchronously and saved asynchronouly
                // we want the keydata to be in the session folder
                let loadedKeyedDataCollection:CollectionOf<KeyedData> = try self.storage.loadSync(fileName: self.keyedDataCollection.fileName, relativeFolderPath: self.sessionIdentifier)
                self.keyedDataCollection = loadedKeyedDataCollection
            }
        }catch FileStorageError.notFound{
            // It may be the first time don't panic
        }catch{
            Logger.log("\(error)", category: .critical)
        }

        self.lastExecutionOrder = self._getLastOrderOfExecution()

        self.upsertCallSequence(CallSequence(name: CallSequence.data, bunchSize: 1))
        self.upsertCallSequence(CallSequence(name: CallSequence.downloads, bunchSize: 1))
        self.upsertCallSequence(CallSequence(name: CallSequence.uploads, bunchSize: 1))

        self._configureCollection(self.keyedDataCollection)


        // Special Call Operations (Downloads and Uploads)
        try self.registerCollection(collection: self.downloads)
        try self.registerCollection(collection: self.uploads)
        // Simple queries
        try self.registerCollection(collection: self.simpleQueries)

        // Generated Models
        try self.registerStandardCallOperationsFor(type: Metrics.self)
        try self.registerStandardCallOperationsFor(type: KeyedData.self)
        try self.registerStandardCallOperationsFor(type: LogEntry.self)
    }
    
    
    /// Registers one upstream and one downstream CallOperation collections
    /// that provision the call for Off line support & fault tolerence
    /// If your CallOperation requires a non-standard signature you should directly call registerCollection
    /// with the registrable collection type
    ///
    /// - Parameter type: the call Payload and resultType
    /// - Throws: erros on collection registration.
    open func registerStandardCallOperationsFor<T:Payload & Result & Collectable>(type:T.Type) throws {
        //self._callOperationsTypes.append(type)
        let upStreamOperations = CallOperation<T,VoidResult>.registrableCollectionProxy
        let downStreamOperations = CallOperation<VoidPayload,T>.registrableCollectionProxy
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
        self._collectionsByFileName[collection.fileName] = collection
        self._collectionsByCollectedTypeName[T.typeName] = collection
        self._collectionsByName[collection.d_collectionName] = collection
    }


    // MARK: - CallSequence


    /// Defines the call sequence.
    /// Should be called during preparation
    ///
    /// - Parameter sequence: the sequence to add.
    public final func upsertCallSequence(_ sequence:CallSequence){
        if let index = self._callSequences.index(where: { $0.name == sequence.name }){
            self._callSequences[index] = sequence
        }else{
            self._callSequences.append(sequence)
        }
    }

    // MARK: -

    /// Returns the collection by its file name
    ///
    /// - Parameter fileName: the fileName of the searched collection
    /// - Returns: the CollectionOf
    public func collection<T>(with fileName:String)->CollectionOf<T>?{
        return self._collectionsByFileName[fileName] as? CollectionOf<T>
    }
    
    
    public var collectionsCount:Int {
        return self._collections.count
    }


    public var collectionsNames:[String] {
        return self._collections.map({$0.d_collectionName})
    }

    
    /// Returns a
    open var debugInformations: String {
        var infos = "---------------"
        infos += "\nDebug informations: \(Date())"
        infos += "\nsessionIdentifier: \(self.sessionIdentifier)"
        infos += "\nNumber of Collections: \(self.collectionsCount)"
        for collectionName in self.collectionsNames.sorted(){
            if let collection = self.collectionNamed(collectionName){
                infos += "\n\(collectionName) count: \(collection.count) selectedCount: \(collection.selectedUIDs.count)"
            }
        }
        return infos
    }


    // MARK: - DataPointProtocol
    
    // The current Host: e.g demo.bartlebys.org
    open lazy var host: String = Default.NOT_SPECIFIED
    
    // The api base path: e.g /api/v1
    open lazy var apiBasePath: String = Default.NOT_SPECIFIED
    
    // MARK: -  SessionDelegate
    
    /// The credentials should generaly not change during the session
    open lazy var credentials: Credentials = Credentials(username: Default.NO_NAME, password: Default.NO_PASSWORD)
    
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
            if let loginData: Data = loginString.data(using: Default.STRING_ENCODING) {
                let base64LoginString: String = loginData.base64EncodedString()
                request.setValue("Basic " + base64LoginString, forHTTPHeaderField: "Authorization")
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
    public final func requestFor<P : Payload>(path: String, queryString: String, method: HTTPMethod, parameter: P) throws -> URLRequest {
        
        var request = try self.requestFor(path: path, queryString: queryString, method: method)
        
        if !(parameter is VoidPayload) && !(parameter is FilePath) {
            // By default we encode the JSON parameter in the body
            // If the Parameter is not void

            try Model.doWithoutEncodingRelations {
                request.httpBody = try JSONEncoder().encode(parameter)
            }
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
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

    // MARK: -

    /// Provisions the operation in the relevent collection
    /// If the collection exceeds the preservationQuota destroys the first entries
    ///
    /// - Parameter operation: the call operation
    /// - Throws: error if the collection hasn't be found
    public func provision<P, R>(_ operation:CallOperation<P, R>) throws{
        
        // Upsert the relevent call Operation collection
        guard let collection = self._collectionsByCollectedTypeName[CallOperation<P, R>.typeName] as? CollectionOf<CallOperation<P, R>> else{
            throw DataPointError.callOperationCollectionNotFound(named: CollectionOf<CallOperation<P, R>>.collectionName)
        }
        
        // Store the call operation into the relevent collection
        collection.upsert(operation)
        try self._addToPendingCalls(operation)
        try self._applyQuotaOn(collection)

    }

    /// Provisions efficiently the array of operations in the relevent collection
    /// Optimized version of the unitary provisioning method
    /// Uses an indexed merge that may be thousand of times faster when provisioning large amount of operations.
    ///
    /// - Parameter operations: the array of the call operations
    /// - Throws: error if the collection hasn't be found or when appending to pending calls.
    public func provision<P, R>(_ operations:[CallOperation<P, R>]) throws{

        // Upsert the relevent call Operation collection
        guard let collection = self._collectionsByCollectedTypeName[CallOperation<P, R>.typeName] as? CollectionOf<CallOperation<P, R>> else{
            throw DataPointError.callOperationCollectionNotFound(named: CollectionOf<CallOperation<P, R>>.collectionName)
        }

        /// Store the call operation into the relevent collection
        /// uses an efficient indexed merge function
        collection.merge(with:operations)
        for operation in operations{
            try self._addToPendingCalls(operation)
        }
        try self._applyQuotaOn(collection)
    }


    /// Turning this to false improves the insertion time
    /// May be used during development to check provisioning anomalies.
    public var throwErrorOnMultipleProvisioningAttempts:Bool = false

    fileprivate func _addToPendingCalls<P,R>(_ operation:CallOperation<P, R>) throws {
        // Append the call operation to the pending Calls
        if !self._sortedPendingCalls.keys.contains(operation.sequenceName){
            self._sortedPendingCalls[operation.sequenceName] = [CallOperationProtocol]()
        }
        if self.throwErrorOnMultipleProvisioningAttempts
            && (self._sortedPendingCalls[operation.sequenceName]?.index(where: { return $0.uid == operation.uid }) != nil){
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


    /// Executes the next Bunch of call Operations for a given the CallSequence
    /// - The call sequences are running in parallel
    ///
    /// - Parameter callSequenceName: the Call sequence name
    public final func executeNextBunchOfCallOperations(from callSequenceName:CallSequence.Name){

        // Block the execution if we are explicitly offLine or paused
        guard self.currentState == .online else{
            return
        }

        if !self.allowBackgroundOperations && self.isRunningInBackGround == true{
            return
        }

        // We recover or create & upsert the call sequence
        let sequence : CallSequence
        if let found = self._callSequences.first(where: { $0.name == callSequenceName} ){
            sequence = found
        }else{
            // We use 1 as bunchSize by default
            sequence = CallSequence(name: callSequenceName, bunchSize: 1)
            self.upsertCallSequence(sequence)
        }

        let bunchSize = sequence.bunchSize

        let futuresWorks = self._futureWorks[callSequenceName] ?? [AsyncWork]()
        let futuresWorksUIDs:[UID] = futuresWorks.map({$0.associatedUID})
        let nbOfFutureWorks = futuresWorks.count


        var runningCounter = 0
        // Are there some running calls?
        for uid in self.runningCallsUIDS{
            if let callOperation = self.registredModelByUID(uid) as? CallOperationProtocol{
                if callOperation.sequenceName == callSequenceName{
                    runningCounter += 1
                }
            }
        }

        let useAsyncWorks = nbOfFutureWorks > 0
        var maxFutureDelay:TimeInterval = 0
        for work in futuresWorks{
            if maxFutureDelay < work.delay{
                maxFutureDelay = work.delay
            }
        }

        // We try to maintain a concurrent bunch of CallOperation
        if runningCounter + nbOfFutureWorks  < bunchSize{

            guard let availableOperations = self._sortedPendingCalls[callSequenceName] else{
                return
            }

            // Optimized filtering (we stop when we have reached the required number of operation)
            // The availableOperations number may be very important.
            var filteredOperations = [CallOperationProtocol]()
            var filterCounter = 0
            for operation in availableOperations{
                // Filter the running and futures works
                if !self.runningCallsUIDS.contains(operation.uid) &&
                    !futuresWorksUIDs.contains(operation.uid){
                    filteredOperations.append(operation)
                    filterCounter += 1
                }
                if filterCounter == bunchSize{
                    break
                }
            }

            let numberOfOperations = filteredOperations.count
            guard numberOfOperations > 0 else{
                return
            }
            let nbOfIteration = min(bunchSize - runningCounter, numberOfOperations)
            for i in 0..<nbOfIteration {
                let callOperation = filteredOperations[i]
                if useAsyncWorks{
                    // Execute after the last future works
                    self._runOperationInAsyncWork(callOperation, delay: maxFutureDelay)
                }else{
                    do{
                        try callOperation.runIfProvisioned()
                    }catch{
                        Logger.log(error, category: .critical)
                    }
                }
            }
        }else{
            // There are enough running or planified (AsyncWork) CallOperation
        }
    }


    /// This method is called by the execution engine for metrology
    ///
    /// - Parameter metrics: the metrics
    open func report(_ metrics:Metrics){
        // You can override this method in your datapoint for metrology
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


    /// Runs the operation in an AsyncWork
    ///
    /// - Parameters:
    ///   - operation: the call operation to be ran
    ///   - delay: the delay before its execution
    fileprivate func _runOperationInAsyncWork(_ operation: CallOperationProtocol,delay:TimeInterval){
        let workItem = DispatchWorkItem.init {
            operation.execute()
        }
        let work = AsyncWork(dispatchWorkItem: workItem, delay: delay, associatedUID:operation.uid)
        if !self._futureWorks.keys.contains(operation.sequenceName){
            self._futureWorks[operation.sequenceName] = [AsyncWork]()
        }
        self._futureWorks[operation.sequenceName]?.append(work)
    }



    fileprivate func _cleanUpFutureWorks<P, R>(_ operation: CallOperation<P, R>){
        // CleanUp the future works
        if let index = self._futureWorks[operation.sequenceName]?.index(where: {$0.associatedUID == operation.uid}){
            self._futureWorks[operation.sequenceName]?.remove(at: index)
        }
    }


    // MARK: - SessionDelegate.CallOperationReceiver

    /// Implements Called on success
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - error: the error
    open func callOperationExecutionDidSucceed<P, R>(_ operation: CallOperation<P, R>) throws{

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
        self.executeNextBunchOfCallOperations(from: operation.sequenceName)
    }


    /// Implements the faulting logic
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - error: the error
    open func callOperationExecutionDidFail<P, R>(_ operation: CallOperation<P, R>, error:Error?) throws {

        defer{
            // Send a notification
            let notificationName = Notification.Name.CallOperation.didFail()
            var userInfo :[AnyHashable : Any] = [Notification.Name.CallOperation.operationKey : operation]
            if let filePath = operation.payload as? FilePath {
                userInfo[Notification.Name.CallOperation.filePathKey] = filePath
            }
            if let error = error {
                userInfo[Notification.Name.CallOperation.errorKey] = error
            }
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo:userInfo)
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
                self.executeNextBunchOfCallOperations(from: sequenceName)
            }else{
                // Blocked & Not Destroyable
                // The operation is Blocked
                // All the CallSequence is stuck
            }
        }else{
            // The Operation is not blocked
            // It means we can try to run again later
            if self.currentState == .online{
                // Re-execution logic
                //We double the reExecutionDelay (may be we should use another strategy)
                operation.reExecutionDelay = min (operation.reExecutionDelay * 2 , self.maxReexecutionDelayInSecond)
                self._runOperationInAsyncWork(operation,delay: operation.reExecutionDelay)
            }else{
                // We are not running live
                // So there is no reason to create an AsyncWork
            }
        }
    }


    // MARK: - Load and Save

    open func save() throws {

        // Store the state in KVS
        try self.storeInKVS(self.lastExecutionOrder, identifiedBy: DataPoint.sessionLastExecutionKVSKey)
        // We add a saving delegate to relay the progression
        self.storage.addProgressObserver (observer: AutoRemovableSavingDelegate(dataPoint: self))
        for collection in self._collections {
            try (collection as? FileSavable)?.saveToFile()
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
        return self._collectionsByCollectedTypeName[T.typeName] as? CollectionOf<T>
    }

    // MARK: -

    // MARK: - Dynamic collections & Dynamic Upsert (e.g: BartlebyKit Triggers)


    /// Recover a collection from its name
    ///
    /// - Returns: the collection
    open func collectionNamed (_ name:String)->IndistinctCollection?{
        return self._collectionsByName[name]
    }

    /// Upsert the serialized data into a named collection.
    ///
    /// - Parameters:
    ///   - data: a serialized item
    ///   - named: the name of the collection
    open func upsertItem (_ data:Data, intoCollection named:String){
        if let collection = self.collectionNamed(named){
            collection.upsertItem(data)
        }
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
            if let callOperations = collection.dynamicCallOperations{
                if let firstElement = callOperations.first{
                    self._sortedPendingCalls[firstElement.sequenceName]?.append(contentsOf: callOperations)
                }
            }
        }
        for sequenceNamed in self._sortedPendingCalls.keys{
            self._sortedPendingCalls[sequenceNamed]?.sort { (lCalOp, rCalOp) -> Bool in
                return lCalOp.scheduledOrderOfExecution < rCalOp.scheduledOrderOfExecution
            }
        }
    }


    // MARK: - CallOperations Level

    /// Provisions the single operation
    /// The execution may occur immediately or not according to the current Load
    /// The order of the call are guaranted not the order of the Results if the Bunchsize is > 1
    ///
    /// - Parameter operation: the call operation
    final internal func execute<P, R>(_ operation:CallOperation<P, R>){

        // Defines the order of execution
        self._prepareExecutionOf(operation)

        //Provision the operation.
        do {
            // Provision the call operation
            try self.provision(operation)
        } catch {
            Logger.log("\(error)", category: .critical)
        }

        // Execute the next bunch
        self.executeNextBunchOfCallOperations(from: operation.sequenceName)

    }

    /// Provides an optimized execution model when using large amounts of operations
    /// The execution may occur immediately or not according to the current Load
    ///
    /// - Parameter operation: the array of call operations
    final internal func execute<P, R>(_ operations:[CallOperation<P, R>]){

        guard let firstOperation = operations.first else{
            return
        }

        // Defines the order of execution and provision the operation.
        for operation in operations{
            self._prepareExecutionOf(operation)
        }

        //Provision the operation.
        do {
            // Provision the call operation
            try self.provision(operations)
        } catch {
            Logger.log("\(error)", category: .critical)
        }

        // Execute the next bunch
        self.executeNextBunchOfCallOperations(from: firstOperation.sequenceName)
    }


    /// Defines the order of execution and provision the operation.
    ///
    /// - Parameter operation: the call operation
    final fileprivate func _prepareExecutionOf<P,R>( _ operation:CallOperation<P, R>){
        // Provision the Operation
        operation.sessionIdentifier = self.identifier
        if operation.scheduledOrderOfExecution == ORDER_OF_EXECUTION_UNDEFINED{
            self.lastExecutionOrder += 1
            // Store the scheduledOrderOfExecution and the sessionIdentifier
            operation.scheduledOrderOfExecution = self.lastExecutionOrder
        }
    }






    /// Runs a call operation immediately
    /// This method should not be called directly
    /// We need to expose publicly due to the necessity give a Generic Context in Dynamic calls
    ///
    /// - Parameter operation: the call operation
    /// - Throws: errors on preflight
    final internal func runProvisionedCallOperation<P, R>(_ operation: CallOperation<P, R>) throws {

        guard operation.scheduledOrderOfExecution > ORDER_OF_EXECUTION_UNDEFINED else{
            throw SessionError.unProvisionedOperation
        }

        guard !self.runningCallsUIDS.contains(operation.uid) else{
            throw SessionError.multipleExecutionAttempts
        }

        self.runningCallsUIDS.append(operation.uid)

        let request: URLRequest = try self.requestFor(operation)
        let failureClosure: ((Failure) -> ()) = { failure in
            syncOnMain {
                // Call the delegate
                do{
                    self._removeOperationFromRunningCalls(operation)
                    // Relay the failure to the Data Point
                    try self.callOperationExecutionDidFail(operation, error: failure.error)
                }catch{
                    Logger.log(error, category: .critical)
                }
                if let callHandler = operation.callHandler{
                    callHandler(operation, failure.httpResponse, failure.error)
                }
            }
        }
        switch R.self {
        case is Download.Type, is Upload.Type:

            guard let filePath = operation.payload as? FilePath else {
                throw DataPointError.payloadShouldBeOfFilePathType
            }

            let successClosure: ((HTTPResponse) -> ()) = { response in
                syncOnMain {
                    self._onSuccessOf(operation,response)
                }
            }

            if R.self is Download.Type {
                self.callDownload(request: request, localFilePath: filePath, success: successClosure, failure: failureClosure)
            } else {
                self.callUpload(request: request, localFilePath: filePath, success: successClosure, failure: failureClosure)
            }
        default:
            self.call(request:request, resultType:R.self, resultIsACollection: operation.resultIsACollection, success: { response in
                syncOnMain {
                    self.integrateResponse(response)
                    self._onSuccessOf(operation,response)
                }
            }, failure: failureClosure)
        }

    }

    /// Implementation of the Call Operation success.
    /// Should be called on the main thread
    ///
    /// - Parameters:
    ///   - operation: the callOperation
    fileprivate func _onSuccessOf<P,R>(_ operation:CallOperation<P,R>,_ httpResponse:HTTPResponse?){
        do{
            self._removeOperationFromRunningCalls(operation)
            try self.callOperationExecutionDidSucceed(operation)
        }catch{
            Logger.log("\(error)", category: .critical)
        }
        if let callHandler = operation.callHandler{
            callHandler(operation, httpResponse,nil)
        }
    }

    /// Removes the CallOperationUID from the Running Calls.
    ///
    /// - Parameter operation: the operation
    fileprivate func _removeOperationFromRunningCalls<P,R>(_ operation:CallOperation<P,R>){
        if let indexOfOperation = self.runningCallsUIDS.index(of: operation.uid){
            self.runningCallsUIDS.remove(at: indexOfOperation)
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
        }catch KeyValueStorageError.keyNotFound(_){
            // it may be the first time
        }catch{
            // That's not normal
            Logger.log("\(error)", category: .critical)
        }
        return ORDER_OF_EXECUTION_UNDEFINED
    }
}
