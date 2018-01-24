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
    public var delegate : DataPointProtocol
    
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
    open static let runUID: String = Utilities.createUID()

    public fileprivate(set) var isRuningLive:Bool = true

    // shortcuts to the delegate
    public var credentials: Credentials { return self.delegate.credentials }
    public var authenticationMethod: AuthenticationMethod  { return self.delegate.authenticationMethod }
    public var scheme:String { return self.delegate.scheme.rawValue }
    public var host:String { return self.delegate.host }
    public var apiBasePath: String { return self.delegate.apiBasePath }
    
    public let startTime = AbsoluteTimeGetCurrent()
    
    
    public init(delegate:DataPointProtocol,lastExecutionOrder:Int ) {
        self.delegate = delegate
        self.lastExecutionOrder = lastExecutionOrder
    }
    
    public var elapsedTime:Double {
        return AbsoluteTimeGetCurrent() - self.startTime
    }
    
    public func infos() -> String {
        return "Version 0.0.0"
    }

    
    // MARK: - Operations Runtime


    /// Provision and Executes the Call operation immediately if runing live
    /// Else the operation is stored with an execution order for future usage.
    ///
    /// - Parameter operation: the call operation
    public func execute<T:Collectable,P>(_ operation: CallOperation<T,P>){
        if operation.scheduledOrderOfExecution != ORDER_OF_EXECUTION_UNDEFINED{
            self.lastExecutionOrder += 1
            // Store the scheduledOrderOfExecution and the sessionIdentifier
            operation.scheduledOrderOfExecution = self.lastExecutionOrder
            operation.sessionIdentifier = self.identifier
            do {
                // Provision the call operation
                try self.delegate.provision(operation)
            } catch {
                Logger.log("Error: \(error)", category: .critical)
            }

        }
        if self.isRuningLive{
            do {
                try self._runCall(operation)
            } catch {
                Logger.log("Error: \(error)", category: .critical)
            }
        }
    }

    fileprivate func _provision<T:Collectable,P>(_ operation: CallOperation<T,P>){

    }

    /// Runs a call operation
    ///
    /// - Parameter operation: the call operation
    /// - Throws: errors on preflight
    fileprivate func _runCall<T: Collectable, P>(_ operation: CallOperation<T, P>) throws {

        let request: URLRequest
        request = try self.delegate.requestFor(operation)
        
        let failureClosure: ((Failure) -> ()) = { response in
            syncOnMain {
                
                let operation = operation
                operation.hasBeenExecuted()
                
                let notificationName = Notification.Name.CallOperation.didFail()
                
                if let error = response.error {
                    // Can be a FileOperationError with associated FilePath
                    NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [Notification.Name.CallOperation.operationKey : operation, Notification.Name.CallOperation.errorKey : error])
                } else {
                    NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [Notification.Name.CallOperation.operationKey : operation])
                }
                
            }
        }
        
        switch T.self {
        case is Download.Type, is Upload.Type:
            
            guard let filePath = operation.payload as? FilePath else {
                throw DataPointError.payloadShouldBeOfFilePathType
            }
            
            let successClosure: ((HTTPResponse) -> ()) = { response in
                syncOnMain {
                    
                    let operation = operation
                    operation.hasBeenExecuted()
                    
                    let notificationName = Notification.Name.CallOperation.didSucceed()
                    
                    NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [Notification.Name.CallOperation.operationKey : operation, Notification.Name.CallOperation.filePathKey : filePath])
                    do{
                        try  self.delegate.deleteCallOperation(operation)
                    }catch{
                        Logger.log("\(error)", category: .critical)
                    }

                }
            }
            
            if T.self is Download.Type {
                self.callDownload(request: request, resultType: T.self, localFilePath: filePath, success: successClosure, failure: failureClosure)
            } else {
                self.callUpload(request: request, resultType: T.self, localFilePath: filePath, success: successClosure, failure: failureClosure)
            }
        default:
            
            self.call(request:request, resultType:T.self, resultIsACollection: operation.resultIsACollection, success: { response in
                syncOnMain {
                    
                    let operation = operation
                    operation.hasBeenExecuted()
                    
                    self.delegate.integrateResponse(response)
                    
                    let notificationName = Notification.Name.CallOperation.didSucceed()
                    NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [Notification.Name.CallOperation.operationKey : operation])
                    do{
                        try self.delegate.deleteCallOperation(operation)
                    }catch{
                        Logger.log("\(error)", category: .critical)
                    }
                }
            }, failure: failureClosure)
        }
        
    }
    
    // MARK: - HTTP Engine
    
    public func call<T>(  request: URLRequest,
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
                            let decoded = try self.delegate.operationsCoder.decodeArrayOf(T.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
                            let dataResponse = DataResponse(result: decoded)
                            dataResponse.metrics = metrics
                            dataResponse.httpStatus = httpResponse.statusCode.status()
                            dataResponse.content = data
                            
                            syncOnMain {
                                success(dataResponse)
                            }
                        }else{
                            let decoded = try self.delegate.operationsCoder.decode(T.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            metrics.totalDuration = (metrics.requestDuration +  metrics.serializationDuration)
                            let dataResponse = DataResponse(result: [decoded])
                            dataResponse.metrics = metrics
                            dataResponse.httpStatus = httpResponse.statusCode.status()
                            dataResponse.content = data
                            
                            syncOnMain {
                                success(dataResponse)
                            }
                        }
                        
                    } catch {
                        syncOnMain {
                            failure(Failure(from : httpResponse.statusCode.status(), and: error))
                        }
                    }
                } else {
                    // There is no data
                    if let error = error {
                        syncOnMain {
                            failure(Failure(from : httpResponse.statusCode.status(), and: error))
                        }
                    } else {
                        syncOnMain {
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
                syncOnMain {
                    let fileError = FileOperationError.errorOn(filePath: localFilePath, error: error)
                    failure(Failure(from: fileError))
                }
            } else if let httpURLResponse = response as? HTTPURLResponse {
                
                guard let tempURL = temporaryURL else {
                    syncOnMain {
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
                    syncOnMain {
                        success(httpResponse)
                    }
                } catch {
                    syncOnMain {
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
                    syncOnMain {
                        let fileError = FileOperationError.errorOn(filePath: localFilePath, error: error)
                        failure(Failure(from: fileError))
                    }
                } else if let httpURLResponse = response as? HTTPURLResponse {
                    
                    switch httpURLResponse.statusCode {
                    case 200...299:
                        let httpResponse = HTTPResponse()
                        httpResponse.httpStatus = httpURLResponse.statusCode.status()
                        httpResponse.metrics = metrics
                        syncOnMain {
                            success(httpResponse)
                        }
                    default:
                        syncOnMain {
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
