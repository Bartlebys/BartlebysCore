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

    // MARK: - Scheduler
    
    //@todo: scheduling ==> schedule the next Call Operation Bunch
    
    // MARK: - Operations Runtime
    
    public func execute<T:Collectible,P>(_ operation: CallOperation<T,P>){
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
    public func runCall<T:Collectible,P>(_ operation: CallOperation<T,P>){
        
        let request:URLRequest
        
        do {
            request = try self.delegate.requestFor(operation)
        } catch {
            Logger.log("Failure operation request creation \(error) \(operation)", category: Logger.Categories.critical)
            return
        }
        
        self.call(request:request, resultType:T.self, resultIsACollection: operation.resultIsACollection, success: { (response) in
            Object.syncOnMain {
                
                let operation = operation
                
                operation.executionCounter += 1
                operation.lastAttemptDate = Date()
                
                self.delegate.integrateResponse(response)
                
                let notificationName = NSNotification.Name.Operation.didSucceed(operation.operationName)
                NotificationCenter.default.post(name:notificationName , object: nil)
                
                self.delegate.deleteOperation(operation)
            }
            
        }, failure:{ (failure) in
            Object.syncOnMain {
                
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
    ///   - multiple: if set to true we try to deserialize a collection
    ///   - completed: the completion handler
    public func call<T:Tolerent>(  request: URLRequest,
                                   resultType: T.Type,
                                   resultIsACollection:Bool,
                                   success: @escaping (_ completion: Response<T>)->(),
                                   failure: @escaping (_ completion: Failure)->()
        ){

        let metrics = Metrics()
        metrics.elapsed = self.elapsedTime
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let serverHasRespondedTime = AbsoluteTimeGetCurrent()
            metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if let data = data {
                    do {
                        if resultIsACollection{
                            let decoded = try self.delegate.coder.decodeArrayOf(T.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
                            let response = Response(httpStatus: httpResponse.statusCode.status(), content: data, result:decoded, error: nil, metrics: metrics)
                            Object.syncOnMain {
                                success(response)
                            }
                        }else{
                            let decoded = try self.delegate.coder.decode(T.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
                            let response = Response(httpStatus: httpResponse.statusCode.status(), content: data, result: [decoded], error: nil, metrics: metrics)
                            Object.syncOnMain {
                                success(response)
                            }
                        }
                        
                    } catch {
                        Object.syncOnMain {
                            failure(Failure(from : httpResponse.statusCode.status(), and: error))
                        }
                    }
                } else {
                    // There is no data
                    if let error = error {
                        Object.syncOnMain {
                            failure(Failure(from : httpResponse.statusCode.status(), and: error))
                        }
                    } else {
                        Object.syncOnMain {
                            let completion: Response = Response(httpStatus: httpResponse.statusCode.status(), content: data, result: Array<T>(), error: nil, metrics: metrics)
                            success(completion)
                        }
                    }
                }
            }
        }
        task.resume()
    }


}
