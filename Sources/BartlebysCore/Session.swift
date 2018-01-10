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
    case fileNotFound
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

    // A unique run identifier that changes on each launch
    open static let runUID: String = Utilities.createUID()

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
    
    public func execute<T:Collectable,P>(_ operation: CallOperation<T,P>){
        self.provisionOperation(operation)
        do {
            try self.runCall(operation)
        } catch {
            Logger.log("Error: \(error)", category: .critical)
        }
    }
    
    /// Insure the persistency of the operation
    ///
    /// - Parameters:
    ///   - operationData: the operation data
    ///   - operationName: the classifier
    public func provisionOperation<T,P>(_ operation: CallOperation<T,P>){
        // @todo! provisionning
    }
    
    /// Run the operation
    ///
    /// - Parameter operation: the operation
    public func runCall<T: Collectable, P>(_ operation: CallOperation<T, P>) throws {
        
        let request: URLRequest
        request = try self.delegate.requestFor(operation)
        
        let failureClosure: ((Failure) -> ()) = { response in
            Object.syncOnMain {
                
                let operation = operation
                
                operation.executionCounter += 1
                operation.lastAttemptDate = Date()
                
                let notificationName = NSNotification.Name.CallOperation.didFail(operation.operationName)
                NotificationCenter.default.post(name:notificationName, object: response.error)
                
            }
        }
        
        switch T.self {
        case is Download.Type, is Upload.Type:
            let successClosure: ((HTTPResponse) -> ()) = { response in
                Object.syncOnMain {
                    
                    let operation = operation
                    
                    operation.executionCounter += 1
                    operation.lastAttemptDate = Date()
                    
                    let notificationName = NSNotification.Name.CallOperation.didSucceed(operation.operationName)
                    NotificationCenter.default.post(name:notificationName , object: nil)
                    
                    self.delegate.deleteCallOperation(operation)
                }
            }
            
            guard let FilePath = operation.payload as? FilePath else {
                throw DataPointError.payloadShouldBeOfFilePathType
            }
            
            if T.self is Download.Type {
                self.callDownload(request: request, resultType: T.self, localFilePath: FilePath, success: successClosure, failure: failureClosure)
            } else {
                self.callUpload(request: request, resultType: T.self, localFilePath: FilePath, success: successClosure, failure: failureClosure)
            }
        default:

            self.call(request:request, resultType:T.self, resultIsACollection: operation.resultIsACollection, success: { response in
                Object.syncOnMain {

                    let operation = operation
                    
                    operation.executionCounter += 1
                    operation.lastAttemptDate = Date()
                    
                    self.delegate.integrateResponse(response)
                    
                    let notificationName = Notification.Name.CallOperation.didSucceed(operation.operationName)
                    NotificationCenter.default.post(name:notificationName, object: nil)
                    
                    self.delegate.deleteCallOperation(operation)
                }
            }, failure: failureClosure)
        }

    }
    
    // MARK: - HTTP Engine
    
    public func call<T:Tolerent>(  request: URLRequest,
                                resultType: T.Type,
                                resultIsACollection:Bool,
                                success: @escaping (_ completion: DataResponse<T>)->(),
                                failure: @escaping (_ completion: Failure)->()
        ) {
        
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
                            let dataResponse = DataResponse(result: decoded)
                            dataResponse.metrics = metrics
                            dataResponse.httpStatus = httpResponse.statusCode.status()
                            dataResponse.content = data
                            
                            Object.syncOnMain {
                                success(dataResponse)
                            }
                        }else{
                            let decoded = try self.delegate.coder.decode(T.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
                            let dataResponse = DataResponse(result: [decoded])
                            dataResponse.metrics = metrics
                            dataResponse.httpStatus = httpResponse.statusCode.status()
                            dataResponse.content = data

                            Object.syncOnMain {
                                success(dataResponse)
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
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)

                            let dataResponse: DataResponse = DataResponse(result: Array<T>())
                            dataResponse.httpStatus = httpResponse.statusCode.status()
                            dataResponse.content = data
                            dataResponse.metrics = metrics
                            success(dataResponse)
                        }
                    }
                }
            }
        }
        task.resume()

    }

    public func callDownload<T>(  request: URLRequest,
                        resultType: T.Type,
                        localFilePath: FilePath,
                        success: @escaping (_ completion: HTTPResponse)->(),
                        failure: @escaping (_ completion: Failure)->()
        ) {

        let metrics = Metrics()
        metrics.elapsed = self.elapsedTime
        
        let task = URLSession.shared.downloadTask(with: request) { (temporaryURL, response, error) in
            
            let serverHasRespondedTime = AbsoluteTimeGetCurrent()
            metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
            metrics.totalDuration = metrics.requestDuration
            
            if let error = error {
                Object.syncOnMain {
                    failure(Failure(from: error))
                }
            } else if let httpURLResponse = response as? HTTPURLResponse {
                
                guard let tempURL = temporaryURL else {
                    Object.syncOnMain {
                        failure(Failure(from: httpURLResponse.statusCode.status(), and: SessionError.fileNotFound))
                    }
                    return
                }
                
                do {
                    let localFileURL = try localFilePath.urlFromSession(session: self)
                    let directoryURL = localFileURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

                    try FileManager.default.moveItem(at: tempURL, to: localFileURL)
                    
                    let httpResponse = HTTPResponse()
                    httpResponse.httpStatus = httpURLResponse.statusCode.status()
                    httpResponse.metrics = metrics
                    Object.syncOnMain {
                        success(httpResponse)
                    }
                } catch {
                    Object.syncOnMain {
                        failure(Failure(from: httpURLResponse.statusCode.status(), and: error))
                    }
                }
            }
            
        }
        task.resume()
    }
    
    public func callUpload<T>(  request: URLRequest,
                      resultType: T.Type,
                      localFilePath: FilePath,
                      success: @escaping (_ completion: HTTPResponse)->(),
                      failure: @escaping (_ completion: Failure)->()
        ) {
        
        let metrics = Metrics()
        metrics.elapsed = self.elapsedTime
        
        do {
            let localFileURL = try localFilePath.urlFromSession(session: self)
            
            let task = URLSession.shared.uploadTask(with: request, fromFile: localFileURL) { (data, response, error) in
                
                let serverHasRespondedTime = AbsoluteTimeGetCurrent()
                metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
                metrics.totalDuration = metrics.requestDuration
                
                if let error = error {
                    Object.syncOnMain {
                        failure(Failure(from: error))
                    }
                } else if let httpURLResponse = response as? HTTPURLResponse {
                    
                    switch httpURLResponse.statusCode {
                    case 200...299:
                        let httpResponse = HTTPResponse()
                        httpResponse.httpStatus = httpURLResponse.statusCode.status()
                        httpResponse.metrics = metrics
                        Object.syncOnMain {
                            success(httpResponse)
                        }
                    default:
                        Object.syncOnMain {
                            failure(Failure(from: httpURLResponse.statusCode.status()))
                        }
                    }
                }
            }
            task.resume()
        } catch {
            failure(Failure(from: error))
        }

    }

}
