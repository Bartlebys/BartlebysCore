//
//  Session.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

enum SessionError : Error {
    case deserializationFailed
}

// Handles a full Session.T
public class Session {
    
    // The Concrete data point implements the SessionDelegate, and any logic required to perform.
    // The session delegate defines the Scheme, Host, Current Credentials, and configures the requests
    public var delegate : ConcreteDataPoint
    
    // A shared void Payload instance
    public static let voidPayload = VoidPayload()

    // The session Identifier
    public var sessionIdentifier: String

    // shortcuts to the delegate
    public var credentials: Credentials { return self.delegate.credentials }
    public var authenticationMethod: AuthenticationMethod  { return self.delegate.authenticationMethod }
    public var scheme:String { return self.delegate.scheme.rawValue }
    public var host:String { return self.delegate.host }
    public var apiBasePath: String { return self.delegate.apiBasePath }
    
    public let startTime = AbsoluteTimeGetCurrent()


    public init(delegate:ConcreteDataPoint,sessionIdentifier:String) {
        self.delegate = delegate
        self.sessionIdentifier = sessionIdentifier
    }
    
    public var elapsedTime:Double {
        return AbsoluteTimeGetCurrent() - self.startTime
    }
    
    public func infos() -> String {
        return "Version 0.0.0"
    }
    
    // MARK: - Thread Safety
    
    public static func syncOnMain(execute block: () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }
    
    public static func syncThrowableOnMain(execute block: () throws -> Void) rethrows-> (){
        if Thread.isMainThread {
            try block()
        } else {
            try DispatchQueue.main.sync(execute: block)
        }
    }
    
    public static func syncOnMainAndReturn<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
    
    // MARK: - Scheduler
    
    //@todo: scheduling ==> schedule the next Call Operation Bunch
    
    // MARK: - Operations Runtime
    
    public func execute<T:Codable,P>(_ operation: CallOperation<T,P>){
        self.provisionOperation(operation)
        self.runCall(operation)
    }
    
    /// Insure the persistency of the operation
    ///
    /// - Parameters:
    ///   - operationData: the operation data
    ///   - operationName: the classifier
    public func provisionOperation<T,P>(_ operation: CallOperation<T,P>){
        // @todo provisionning
    }
    
    /// Run the operation
    ///
    /// - Parameter operation: the operation
    public func runCall<T:Codable,P>(_ operation: CallOperation<T,P>){
        
        let request:URLRequest
        
        do{
            request = try self.delegate.requestFor(operation)
        }catch{
            Logger.log("Failure operation request creation \(error) \(operation)", category: Logger.Categories.critical)
            return
        }
        
        self.call(request:request, resultType:[T].self,success: { (response) in
            Session.syncOnMain {
                
                let operation = operation
                
                operation.executionCounter += 1
                operation.lastAttemptDate = Date()
                
                self.delegate.integrateResponse(response)
                
                let notificationName = NSNotification.Name.Operation.didSucceed(operation.operationName)
                NotificationCenter.default.post(name:notificationName , object: nil)
                
                self.delegate.deleteOperation(operation)
            }
            
        }, failure:{ (failure) in
            Session.syncOnMain {
                
                let operation = operation
                
                operation.executionCounter += 1
                operation.lastAttemptDate = Date()
                
                let notificationName = NSNotification.Name.Operation.didFail(operation.operationName)
                NotificationCenter.default.post(name:notificationName , object: nil)
                
            }
        })
    }
    
    
    // MARK: - HTTP Engine
    
    /// Generic Server call
    ///
    /// - Parameters:
    ///   - request : the URL request
    ///   - resultType: the type of the result
    ///   - completed: the completion handler
    public func call<T>(  request: URLRequest,
                            resultType: Array<T>.Type,
                            success: @escaping (_ completion: Response<T>)->(),
                            failure: @escaping (_ completion: Failure)->()
                        ) where T : TolerentDeserialization {

        var metrics = Metrics()
        metrics.elapsed = self.elapsedTime
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let serverHasRespondedTime = AbsoluteTimeGetCurrent()
            metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if let data = data {
                    
                    let isACollection = self._dataMayContainMultipleJsonObjects(data: data)
                    
                    do {
                        // Try without patching the the data
                        let response = try self._deserialize(httpResponse: httpResponse, isACollection: isACollection, type: T.self, data: data, metrics: &metrics, serverHasRespondedTime: serverHasRespondedTime)
                        Session.syncOnMain {
                            success(response)
                        }
                    } catch {
                        
                        
                        
                        // The Json Object are not fully compliant with the Strong Types.
                        // We gonna try to patch the data
                        do {
                            if isACollection{
                                // Patch the collection
                                
                                let patchedData = try self._patchCollection(data: data, resultType: T.self)
                                let response = try self._deserialize(httpResponse: httpResponse, isACollection: true, type: T.self, data: patchedData, metrics: &metrics, serverHasRespondedTime: serverHasRespondedTime)
                                Session.syncOnMain {
                                    success(response)
                                }
                            }else{
                                // Patch the object
                                let patchedData = try self._patchObject(data: data, resultType: T.self)
                                let response = try self._deserialize(httpResponse: httpResponse, isACollection: false, type: T.self, data: patchedData, metrics: &metrics, serverHasRespondedTime: serverHasRespondedTime)
                                Session.syncOnMain {
                                    success(response)
                                }
                            }
                        } catch {
                            Session.syncOnMain {
                                failure(Failure(from : httpResponse.statusCode.status(), and: error))
                            }
                        }
                        
                    }
                    
                } else {
                    
                    // There is no data
                    if let error = error {
                        Session.syncOnMain {
                            failure(Failure(from : httpResponse.statusCode.status(), and: error))
                        }
                    } else {
                        let completion: Response = Response(httpStatus: httpResponse.statusCode.status(), content: data, result: Array<T>(), error: nil, metrics: metrics)
                        Session.syncOnMain {
                            success(completion)
                        }
                    }
                }
            }
            
        }
        task.resume()
    }
    
    
    /// Deserializes the data
    ///
    /// - Parameters:
    ///   - httpResponse: the reference to the httpResponse
    ///   - isACollection: is it a possibly a collection?
    ///   - type: the type
    ///   - data: the data
    /// - Returns: the response
    /// - Throws: JSON
    fileprivate func _deserialize<T:Codable>(httpResponse:HTTPURLResponse,isACollection:Bool, type:T.Type ,data: Data,metrics:inout Metrics,serverHasRespondedTime:Double) throws -> Response<T> {
        let currentTime = AbsoluteTimeGetCurrent()
        if isACollection{
            let collection: Array<T> = try JSON.decoder.decode(Array<T>.self, from: data) as Array<T>
            metrics.serializationDuration = currentTime - serverHasRespondedTime
            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
            return Response(httpStatus: httpResponse.statusCode.status(), content: data, result: collection, error: nil, metrics: metrics)
        }else{
            let object: T = try JSON.decoder.decode(T.self, from: data) as T
            // Pack the Object in an Array and return the response
            metrics.serializationDuration = currentTime - serverHasRespondedTime
            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
            return Response(httpStatus: httpResponse.statusCode.status(), content: data, result: [object], error: nil, metrics: metrics)
        }
    }
    
    
    /// Determinate if a data is possibly a JSON collection
    ///
    /// - Parameter data: the data
    /// - Returns: true if the JSON is posssibly a collection (there is no semantic validation of the JSON)
    fileprivate func _dataMayContainMultipleJsonObjects(data: Data)->Bool{
        // this implementation is sub-optimal.
        if let string = String(data: data, encoding: String.Encoding.utf8){
            // We have the string let's log it
            Logger.log(string,category: .temporary)
            for c in string{
                if c == "["{
                    return true
                }
                if c == "{"{
                    break
                }
            }
        }
        return false
    }
    
    // MARK: -  TolerentDeserialization Patches
    
    /// Patches JSON data according to the attended Type
    ///
    /// - Parameters:
    ///   - data: the data
    ///   - resultType: the result type
    /// - Returns: the patched data
    fileprivate func _patchObject<T>(data: Data, resultType: T.Type) throws -> Data where T : TolerentDeserialization {
        return try Session.syncOnMainAndReturn(execute: { () -> Data in
            if var jsonDictionary = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments, JSONSerialization.ReadingOptions.mutableLeaves, JSONSerialization.ReadingOptions.mutableContainers]) as? Dictionary<String, Any> {
                resultType.patchDictionary(&jsonDictionary)
                return try JSONSerialization.data(withJSONObject:jsonDictionary, options:[])
            }else{
                throw SessionError.deserializationFailed
            }
        })
    }
    
    /// Patches collection of JSON data according to the attended Type
    ///
    /// - Parameters:
    ///   - data: the data
    ///   - resultType: the result type
    /// - Returns: the patched data
    fileprivate func _patchCollection<T>(data: Data, resultType: T.Type) throws -> Data where T : TolerentDeserialization {
        return try Session.syncOnMainAndReturn(execute: { () -> Data in
            if var jsonObject = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments, JSONSerialization.ReadingOptions.mutableLeaves, JSONSerialization.ReadingOptions.mutableContainers]) as? Array<Dictionary<String, Any>> {
                var index = 0
                for var jsonElement in jsonObject {
                    resultType.patchDictionary(&jsonElement)
                    jsonObject[index] = jsonElement
                    index += 1
                }
                return try JSONSerialization.data(withJSONObject: jsonObject, options:[])
            }else{
                throw SessionError.deserializationFailed
            }
        })
        
    }
    
}
