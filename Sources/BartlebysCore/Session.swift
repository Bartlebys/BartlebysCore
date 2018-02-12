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
    case multipleExecutionAttempts
    case unProvisionedOperation
}

// Created in a DataPoint
// Used to define the context of networking operations
// And execute & re-execute Request & CallOperations
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

    public fileprivate(set) var isRunningLive:Bool = true

    // We store the running call operations UIDS
    public fileprivate(set) var runningCallsUIDS = [UID]()

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


    /// Applies the current delegate state
    /// This is the only method to setup self.isRunningLive
    /// It is called by the DataPoint on state transition
    public func applyState(){
        let newState = self.delegate.currentState
        switch newState{
        case .online:
            self.isRunningLive = true
        case .offline:
            self.isRunningLive = false
        }
    }

    public var elapsedTime:Double {
        return AbsoluteTimeGetCurrent() - self.startTime
    }
    
    public func infos() -> String {
        return "v1.1.0"
    }

    
    // MARK: - CallOperations Level


    /// Provisions the operation
    /// The execution may occur immediately or not according to the current Load
    /// The order of the call are guaranted not the order of the Results if the Bunchsize is > 1
    ///
    /// - Parameter operation: the call operation
    /// - Throws: error if the collection hasn't be found
    public func execute<P, R>(_ operation:CallOperation<P, R>){
        self._provision(operation)
        if self.isRunningLive {
            self.delegate.executeNextBunchOfCallOperations(from: operation.sequenceName)
        }
    }


    fileprivate func _provision<P,R>(_ operation:CallOperation<P,R>){
        operation.sessionIdentifier = self.identifier
        if operation.scheduledOrderOfExecution == ORDER_OF_EXECUTION_UNDEFINED{
            self.lastExecutionOrder += 1
            // Store the scheduledOrderOfExecution and the sessionIdentifier
            operation.scheduledOrderOfExecution = self.lastExecutionOrder
            do {
                // Provision the call operation
                try self.delegate.provision(operation)
            } catch {
                Logger.log("\(error)", category: .critical)
            }
        }
    }

    
    /// Runs a call operation
    ///
    /// - Parameter operation: the call operation
    /// - Throws: errors on preflight
    public final func runCall<P, R>(_ operation: CallOperation<P, R>) throws {

        guard operation.scheduledOrderOfExecution > ORDER_OF_EXECUTION_UNDEFINED else{
            throw SessionError.unProvisionedOperation
        }

        guard !self.runningCallsUIDS.contains(operation.uid) else{
            throw SessionError.multipleExecutionAttempts
        }

        self.runningCallsUIDS.append(operation.uid)

        let request: URLRequest = try self.delegate.requestFor(operation)
        let failureClosure: ((Failure) -> ()) = { response in
            syncOnMain {
                // Call the delegate
                do{
                    self._removeOperationFromRunningCalls(operation)
                    // Relay the failure to the Data Point
                    try self.delegate.callOperationExecutionDidFail(operation,error:response.error)
                }catch{
                    Logger.log(error, category: .critical)
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
                    self._onSuccessOf(operation)
                }
            }
            
            if R.self is Download.Type {
                self.callDownload(request: request, resultType: R.self, localFilePath: filePath, success: successClosure, failure: failureClosure)
            } else {
                self.callUpload(request: request, resultType: R.self, localFilePath: filePath, success: successClosure, failure: failureClosure)
            }
        default:
            self.call(request:request, resultType:R.self, resultIsACollection: operation.resultIsACollection, success: { response in
                syncOnMain {
                    self.delegate.integrateResponse(response)
                    self._onSuccessOf(operation)
                }
            }, failure: failureClosure)
        }
        
    }

    /// Implementation of the Call Operation success.
    /// Should be called on the main thread
    ///
    /// - Parameters:
    ///   - operation: the callOperation
    fileprivate func _onSuccessOf<P,R>(_ operation:CallOperation<P,R>){
        do{
            self._removeOperationFromRunningCalls(operation)
            try self.delegate.callOperationExecutionDidSucceed(operation)
        }catch{
            Logger.log("\(error)", category: .critical)
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

    // MARK: - HTTP Engine (Request level)
    
    public func call<R>(  request: URLRequest,
                          resultType: R.Type,
                          resultIsACollection:Bool,
                          success: @escaping (_ completion: DataResponse<R>)->(),
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
                            let decoded = try self.delegate.operationsCoder.decodeArrayOf(R.self, from: data)
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
                            let decoded = try self.delegate.operationsCoder.decode(R.self, from: data)
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
                            
                            let dataResponse: DataResponse = DataResponse(result: Array<R>())
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
    
    public func callDownload<R>(  request: URLRequest,
                                  resultType: R.Type,
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
    
    public func callUpload<R>(  request: URLRequest,
                                resultType: R.Type,
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
