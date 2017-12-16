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
}

// Abstract class
open class DataPoint : ConcreteDataPoint {
    
    // MARK: -

    /// The file 
    public var coder: ConcreteCoder

    /// The associated session
    public lazy var session:Session = Session(delegate: self, sessionIdentifier:self.sessionIdentifier)
    
    /// Its session identifier
    public var sessionIdentifier: String = "NOT_IDENTIFIED"

    
    /// Initialization of the DataPoint
    ///
    /// - Parameters:
    ///   - credentials: the current credentials
    ///   - sessionIdentifier: a unique session identifier (should be persistent as it is used to compute serialization paths)
    ///   - coder: the persistency layer a coder == a consistent Encoder / Decoder pair.
    /// - Throws: Children may throw while populating the collections
    required public init(credentials:Credentials, sessionIdentifier:String, coder: ConcreteCoder) throws{
        self.credentials = credentials
        self.sessionIdentifier = sessionIdentifier
        self.coder = coder
    }

    /// Contains all the data Point collections
    /// You can populate with concrete types (polymorphism)
    ///
    /// Concrete return could be for example :
    ///     return [ ObjectCollection<Event>(), ObjectCollection<Tag>()]
    /// - Returns: the data Point model collections
    fileprivate var _collectionsOfModels:[Any] = Array<Any>()

    /// We use the same polymorphic approach for the call Operations
    /// Call operation are also collection of Models
    //  The concrete type should be `CallOperation<T,P>`
    fileprivate var _collectionsOfCallOperations:[Any] =  Array<Any>()

    /// Registers the collection in to the data point
    ///
    /// - Parameter collection: the collection
    public func registerCollection<T>(collection:ObjectCollection<T>){
        self._collectionsOfModels.append(collection)
    }

    public func collectionOfModelsCount() -> Int {
        return self._collectionsOfModels.count
    }
    
    /// Register the the callOperationCollection in to the data point
    ///
    /// - Parameter callOperationCollection: the callOperation Collection
    public func registerCallOperationCollection<T,P>(callOperationCollection:ObjectCollection<CallOperation<T,P>>){
        self._collectionsOfCallOperations.append(callOperationCollection)
    }

    // MARK: - ConcreteDataPoint

    // The current Host: e.g demo.bartlebys.org
    open var host: String = "NO_HOST"
    
    // The api base path: e.g /api/v1
    open var apiBasePath: String = "NO_BASE_API_PATH"

    // MARK: -  SessionDelegate

    /// The credentials should generaly not change during the session
    open var credentials: Credentials
    
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
        if let firstCollection = self._collectionsOfModels.first(where:{ $0 as? ObjectCollection<T> != nil }) {
            if let concreteCollection = firstCollection as? ObjectCollection<T>{
                for instance in response.result {
                    concreteCollection.upsert(instance)
                }
            }
        }
    }

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    public final func deleteOperation<T,P>(_ operation: CallOperation<T,P>){
        if let pendingCallOperations = self._collectionsOfCallOperations.first(where:{ $0 as? CallOperation<T,P> != nil }) as? ObjectCollection<CallOperation<T,P>> {
            
            if let idx = pendingCallOperations.index(where: { $0.id == operation.id }) {
                let _ = pendingCallOperations.remove(at: idx)
            }
        }
    }


    // MARK: -

    public final func save() throws {
        try self.save(using: self.coder)
    }

    /// Saves all the collections.
    ///
    /// - Throws: throws an exception if any save operation has failed
    public final func save(using encoder: ConcreteCoder) throws {
        for collection in self._collectionsOfModels {
            if let concreteCollection = collection as? FilePersistentCollection & UniversalType{
                try concreteCollection.saveToFile(fileName: concreteCollection.d_collectionName, relativeFolderPath: self.sessionIdentifier,using: encoder)
            }
        }
        for collection in self._collectionsOfCallOperations{
            if let concreteCollection = collection as? FilePersistentCollection & UniversalType{
                try concreteCollection.saveToFile(fileName: concreteCollection.d_collectionName, relativeFolderPath: self.sessionIdentifier,using: encoder)
            }
        }
    }

}
