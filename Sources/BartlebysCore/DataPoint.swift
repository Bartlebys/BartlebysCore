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
}

public protocol DataPointDelegate{
    func collectionDidLoadSuccessFully()
    func collectionDidFailToLoad(message:String)
    func collectionDidSaveSuccessFully()
    func collectionDidFailToSave(message:String)
}

struct DataPointDelegatePlaceHolder:DataPointDelegate {
    func collectionDidLoadSuccessFully(){}
    func collectionDidFailToLoad(message:String){}
    func collectionDidSaveSuccessFully(){}
    func collectionDidFailToSave(message:String){}
}

// Abstract class
open class DataPoint: Object,ConcreteDataPoint{
    
    // MARK: -

    /// The coder: encodes and decodes the Data
    public var coder: ConcreteCoder = JSONCoder()

    public var delegate: DataPointDelegate = DataPointDelegatePlaceHolder()

    // The storage IO object: reads an writes the ObjectsCollections
    public var storage = Storage()

    // The base URL
    public var baseWrapperURL:URL{
        get{
            return self.storage.baseUrl
        }
        set{
            self.storage.baseUrl = newValue
        }
    }

    /// The associated session
    public lazy var session:Session = Session(delegate: self, sessionIdentifier:self.sessionIdentifier)
    
    /// Its session identifier
    public var sessionIdentifier: String = "NOT_IDENTIFIED"

    /// Contains all the data Point collections
    /// Populated by registerCollection
    /// - Returns: the data Point model collections
    fileprivate var _collections:[Any] = Array<Any>()

    /// The collection hashed per fileName
    fileprivate var _collectionsPerFileName = Dictionary<String,Any>()

    // this centralized dictionary allows to access to any referenced object by its UID
    // Future versions will use A binary tree.
    fileprivate var _instancesByUID=Dictionary<String, Any>()

    /// Defered Ownership
    /// If we receive a Instance that refers to an unexisting Owner
    /// We store its missing entry is the deferredOwnerships dictionary
    /// For future resolution (on registration)
    /// [notAvailableOwnerUID][relatedOwnedUIDS]
    fileprivate var _deferredOwnerships=[UID:[UID]]()

    // MARK: -


    /// Initializes the dataPoint
    /// - Throws: Children may throw while populating the collections
    required public override init(){
        super.init()
        // The loading is asynchronous on separate queue.
        self.storage.addProgressObserver (observer: DataPointLoadingDelegate(dataPoint: self))
    }


    // MARK: -

    /// That the place where you should call : self.registerCollection(concreteCollection)
    open func prepareCollections()throws{

    }

    /// Registers the collection into the data point
    ///
    /// - Parameter collection: the collection
    open func registerCollection<T>(collection:CollectionOf<T>)throws{

        if !self._collections.contains(where: { (existingCollection) -> Bool in
            if let c = existingCollection as? CollectionOf<T>{
                return c.d_collectionName == collection.d_collectionName && c.fileName == collection.fileName
            }
            return false
        }){
            self._collections.append(collection)
            self._collectionsPerFileName[collection.fileName] = collection
            collection.dataPoint = self

            // Creates or asynchronously load the collection on registration
            self.storage.load(on: collection)

        }else{
            throw DataPointError.duplicatedRegistration(fileName: collection.fileName)
        }
    }


    /// Returns the collection by file name
    ///
    /// - Parameter fileName: the fileName of the searched collection
    /// - Returns: the CollectionOf
    public func collection<T>(with fileName:String)->CollectionOf<T>?{
        return self._collectionsPerFileName[fileName] as? CollectionOf<T>
    }

    
    public func collectionsCount() -> Int {
        return self._collections.count
    }

    
    // MARK: - ConcreteDataPoint

    // The current Host: e.g demo.bartlebys.org
    open var host: String = "NO_HOST"
    
    // The api base path: e.g /api/v1
    open var apiBasePath: String = "NO_BASE_API_PATH"

    // MARK: -  SessionDelegate

    /// The credentials should generaly not change during the session
    open var credentials: Credentials = Credentials(username: "NO_NAME", password: "NO_PASSWORD")
    
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

    /// Returns the relevent request for a given call Operation
    ///
    /// - Parameter operation: the operation
    /// - Returns: the URL request
    /// - Throws: issue on URL creation and operation Parameters serialization
    public final func requestFor<T,P>(_ operation: CallOperation<T,P>) throws -> URLRequest {

        if T.self is Download.Type || T.self is Upload.Type {
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
    public final func integrateResponse<T:Tolerent>(_ response: DataResponse<T>) {
        if let firstCollection = self._collections.first(where:{ $0 as? CollectionOf<T> != nil }) {
            if let concreteCollection = firstCollection as? CollectionOf<T>{
                for instance in response.result {
                    concreteCollection.upsert(instance)
                }
            }
        }
    }

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    public final func deleteCallOperation<T,P>(_ operation: CallOperation<T,P>){
        if let pendingCallOperations = self._collections.first(where:{
            if let callOp =  $0 as? CallOperation<T,P>{
                return callOp.operationName == operation.operationName
            }else{
                return false
            }
        }) as? CollectionOf<CallOperation<T,P>> {
            if let idx = pendingCallOperations.index(where: { $0.id == operation.id }) {
                let _ = pendingCallOperations.remove(at: idx)
            }
        }
    }


    // MARK: - Load and Save

    public final func save() throws {
        // We add a saving delegate to relay the progression
        self.storage.addProgressObserver (observer: DataPointSavingDelegate(dataPoint: self))
        try self.save(using: self.coder)
    }
    

    /// Saves all the collections.
    ///
    /// - Throws: throws an exception if any save operation has failed
    public final func save(using encoder: ConcreteCoder) throws {
        for collection in self._collections {
            if let universallyPersistentCollection = collection as? FilePersistent {
                try universallyPersistentCollection.saveToFile(encoder)
            }
        }
    }

    /// Called before erasure by ManagedModel.erase() of a managedModel Descendant
    /// You should override this method to perform for example associated files deletions...
    ///
    /// - Parameter instance: the managedModel
    open func willErase(_ instance:ManagedModel){}

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
    public func register<T:  Codable & Collectible >(_ instance: T) {
        // Store the instance by its UID
        self._instancesByUID[instance.id]=instance

        // Check if some deferred Ownership has been recorded
        if let owneesUIDS = self._deferredOwnerships[instance.id] {
            /// This situation occurs for example
            /// when the ownee has been triggered but not the owner
            // or the deserialization of the ownee preceeds the owner
            if let o=instance as? ManagedModel{
                for owneeUID in  owneesUIDS{
                    if let _ = self.registredManagedModelByUID(owneeUID){
                        // Add the owns entry
                        if !o.owns.contains(owneeUID){
                            o.owns.append(owneeUID)
                        }else{
                            Swift.print("### !")
                        }
                    }else{
                        Logger.log("Deferred ownership has failed to found \(owneeUID) for \(o.id)", category: Logger.Categories.critical)
                    }
                }
            }
            self._deferredOwnerships.removeValue(forKey: instance.id)
        }
    }


    /// Removes the registred instance from the registry
    ///
    /// - Parameter instance: the instance
    public func unRegister<T:  Codable & Collectible >(_ instance: T) {
        self._instancesByUID.removeValue(forKey: instance.id)
    }

    /// Removes the registred instances from the registry
    ///
    /// - Parameter instance: the instance
    public func unRegister<T:  Codable & Collectible >(_ instances: [T]) {
        for instance in instances{
            self.unRegister(instance)
        }
    }

    /// Returns the registred instance of by its UID
    ///
    /// - Parameter UID: the instance unique identifier
    /// - Returns: the instance
    public func registredObjectByUID<T: Codable & Collectible>(_ UID: UID) throws-> T {
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
    public func registredObjectsByUIDs<T: Collectible & Collectible >(_ UIDs: [UID]) throws-> [T] {
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


    /// Returns a ManagedModel by its UID
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectible>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredManagedModelByUID(_ UID: UID)-> ManagedModel? {
        return try? self.registredObjectByUID(UID)
    }

    /// Returns a collection of ManagedModel by UIDs
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectible>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredManagedModelByUIDs(_ UIDs: [UID])-> [ManagedModel]? {
        return try? self.registredObjectsByUIDs(UIDs)
    }

    ///  Returns the instance by its UID
    ///
    /// - Parameter UID: needle
    /// - Returns: the instance
    public func collectibleInstanceByUID<T:Codable & Collectible>(_ UID: UID) -> T? {
        return self._instancesByUID[UID] as? T
    }

    /// Stores the ownee when the owner is not already available
    /// This situation may occur for example on collection deserialization
    /// when the owner is deserialized before the ownee.
    ///
    /// - Parameters:
    ///   - ownee: the ownee
    ///   - ownerUID: the currently unavailable owner UID
    public func appendToDeferredOwnershipsList<T:Codable & Collectible>(_ ownee:T,ownerUID:UID){
        if self._deferredOwnerships.keys.contains(ownerUID) {
            self._deferredOwnerships[ownerUID]!.append(ownee.id)
        }else{
            self._deferredOwnerships[ownerUID]=[ownee.id]
        }
    }

}

