//
//  DataPoint+Execution.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 12/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public enum DataPointHTTPError:Error{
    case invalidStatus(statusCode:Int)
    case responseCastingError(response:URLResponse?, error: Error?)
}

extension DataPoint{
    
    // MARK: - HTTP Engine (Request level)
    
    /// Simple request call without deserialization
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - success: the success call back
    ///   - failure: the failure call back
    public func call( request: URLRequest,
                      success: @escaping (_ completion: HTTPResponse)->(),
                      failure: @escaping (_ completion: Failure)->()){

        self.callsCounter += 1

        let metrics = Metrics()
        metrics.associatedURL = request.url
        metrics.elapsed = self.elapsedTime
        
        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            
            defer{
                self.report(metrics)
            }
            
            let serverHasRespondedTime = AbsoluteTimeGetCurrent()
            metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
            
            guard let httpURLResponse = response as? HTTPURLResponse else{
                self.errorCounter += 1
                syncOnMain {
                    failure(Failure(from : DataPointHTTPError.responseCastingError(response: response, error: error)))
                }
                return
            }
            
            let httpResponse = HTTPResponse(metrics: metrics, httpStatus: httpURLResponse.statusCode.status(), content: data)
            
            if let error = error {
                self.errorCounter += 1
                syncOnMain {
                    failure(Failure(from : httpResponse , and: error))
                }
            }else{
                
                guard 200 ... 299 ~= httpURLResponse.statusCode else{
                    self.errorCounter += 1
                    syncOnMain {
                        failure(Failure(from : httpResponse , and: DataPointHTTPError.invalidStatus(statusCode: httpURLResponse.statusCode)))
                    }
                    return
                }
                
                // Success
                syncOnMain {
                    success(httpResponse)
                }
            }
            
        }
        task.resume()
    }
    
    /// Request call with an attended ResultType
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - resultType: the resultType
    ///   - resultIsACollection: is the result a collection?
    ///   - success: the success call back
    ///   - failure: the failure call back
    public func call<R>(  request: URLRequest,
                          resultType: R.Type,
                          resultIsACollection:Bool,
                          success: @escaping (_ completion: DataResponse<R>)->(),
                          failure: @escaping (_ completion: Failure)->()) {

        self.callsCounter += 1

        let metrics = Metrics()
        metrics.associatedURL = request.url
        metrics.elapsed = self.elapsedTime
        
        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            
            defer{
                self.report(metrics)
            }
            
            let serverHasRespondedTime = AbsoluteTimeGetCurrent()
            metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
            
            guard let httpURLResponse = response as? HTTPURLResponse else{
                self.errorCounter += 1
                syncOnMain {
                    failure(Failure(from : DataPointHTTPError.responseCastingError(response: response, error: error)))
                }
                return
            }
            
            if let error = error {
                self.errorCounter += 1
                syncOnMain {
                    let dataResponse = DataResponse(result:Array<R>(), content: nil, metrics: metrics, httpStatus: httpURLResponse.statusCode.status())
                    failure(Failure(from : dataResponse , and: error))
                }
            }else{
                
                guard 200 ... 299 ~= httpURLResponse.statusCode else{
                    self.errorCounter += 1
                    syncOnMain {
                        let dataResponse = DataResponse(result: Array<R>(), content: data, metrics: metrics, httpStatus: httpURLResponse.statusCode.status())
                        failure(Failure(from : dataResponse , and: DataPointHTTPError.invalidStatus(statusCode: httpURLResponse.statusCode)))
                    }
                    return
                }
                
                if let data = data, !(resultType is VoidResult.Type) {
                    do {
                        if resultIsACollection {
                            let decoded = try self.operationsCoder.decodeArrayOf(R.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            let dataResponse = DataResponse(result: decoded, content: data, metrics: metrics, httpStatus: httpURLResponse.statusCode.status())
                            syncOnMain {
                                success(dataResponse)
                            }
                        } else {
                            let decoded = try self.operationsCoder.decode(R.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            let dataResponse = DataResponse(result: [decoded], content: data, metrics: metrics, httpStatus: httpURLResponse.statusCode.status())
                            syncOnMain {
                                success(dataResponse)
                            }
                        }
                    } catch {
                        self.errorCounter += 1
                        syncOnMain {
                            let dataResponse = DataResponse(result:Array<R>(), content: data, metrics: metrics, httpStatus: httpURLResponse.statusCode.status())
                            failure(Failure(from : dataResponse, and: error))
                        }
                    }
                } else {
                    // There is no data
                    syncOnMain {
                        metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                        let dataResponse: DataResponse = DataResponse(result: Array<R>(),content: nil,metrics: metrics, httpStatus: httpURLResponse.statusCode.status())
                        success(dataResponse)
                    }
                }
            }
            
        }
        task.resume()
        
    }
    
    
    /// Call a download task
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - localFilePath: the local file path
    ///   - success: the success call back
    ///   - failure: the failure call back
    public func callDownload(  request: URLRequest,
                               localFilePath: FilePath,
                               success: @escaping (_ completion: HTTPResponse)->(),
                               failure: @escaping (_ completion: Failure)->()) {

        self.callsCounter += 1

        let metrics = Metrics()
        metrics.associatedURL = request.url
        metrics.elapsed = self.elapsedTime
        metrics.streamOrientation = .downStream
        
        let task = self.urlSession.downloadTask(with: request) { (temporaryURL, response, error) in
            
            defer {
                self.report(metrics)
            }
            
            let serverHasRespondedTime = AbsoluteTimeGetCurrent()
            metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
            
            guard let httpURLResponse = response as? HTTPURLResponse else{
                self.errorCounter += 1
                syncOnMain {
                    failure(Failure(from : DataPointHTTPError.responseCastingError(response: response, error: error)))
                }
                return
            }
            
            if let error = error {
                self.errorCounter += 1
                syncOnMain {
                    let fileError = FileOperationError.errorOn(filePath: localFilePath, error: error)
                    failure(Failure(from: fileError))
                }
            } else {
                
                
                let httpResponse = HTTPResponse(metrics: metrics, httpStatus: httpURLResponse.statusCode.status(), content: nil)
                
                if let error = error {
                    self.errorCounter += 1
                    syncOnMain {
                        failure(Failure(from : httpResponse , and: error))
                    }
                }else{
                    
                    guard 200 ... 299 ~= httpURLResponse.statusCode else{
                        self.errorCounter += 1
                        syncOnMain {
                            failure(Failure(from : httpResponse , and: DataPointHTTPError.invalidStatus(statusCode: httpURLResponse.statusCode)))
                        }
                        return
                    }
                    
                    guard let tempURL = temporaryURL else {
                        self.errorCounter += 1
                        syncOnMain {
                            failure(Failure(from: httpResponse, and: SessionError.fileNotFound))
                        }
                        return
                    }
                    
                    
                    do {
                        let localFileURL = try localFilePath.absoluteFileURL()
                        let directoryURL = localFileURL.deletingLastPathComponent()
                        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                        try FileManager.default.moveItem(at: tempURL, to: localFileURL)
                        syncOnMain {
                            success(httpResponse)
                        }
                    } catch {
                        self.errorCounter += 1
                        syncOnMain {
                            failure(Failure(from: httpResponse, and: error))
                        }
                    }
                }
                
            }
        }
        task.resume()
    }
    
    
    /// Call a upload task
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - localFilePath: the local file path
    ///   - success: the success call back
    ///   - failure: the failure call back
    public func callUpload( request: URLRequest,
                            localFilePath: FilePath,
                            success: @escaping (_ completion: HTTPResponse)->(),
                            failure: @escaping (_ completion: Failure)->()) {

        self.callsCounter += 1

        let metrics = Metrics()
        metrics.associatedURL = request.url
        metrics.elapsed = self.elapsedTime
        
        do {
            let localFileURL = try localFilePath.absoluteFileURL()
            
            let task = self.urlSession.uploadTask(with: request, fromFile: localFileURL) { (data, response, error) in
                
                defer {
                    self.report(metrics)
                }
                
                let serverHasRespondedTime = AbsoluteTimeGetCurrent()
                metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)
                
                guard let httpURLResponse = response as? HTTPURLResponse else{
                    self.errorCounter += 1
                    syncOnMain {
                        failure(Failure(from : DataPointHTTPError.responseCastingError(response: response, error: error)))
                    }
                    return
                }
                
                if let error = error {
                    self.errorCounter += 1
                    syncOnMain {
                        let fileError = FileOperationError.errorOn(filePath: localFilePath, error: error)
                        failure(Failure(from: fileError))
                    }
                } else {
                    
                    let httpResponse = HTTPResponse(metrics: metrics, httpStatus: httpURLResponse.statusCode.status(), content: nil)
                    
                    guard 200 ... 299 ~= httpURLResponse.statusCode else{
                        self.errorCounter += 1
                        syncOnMain {
                            failure(Failure(from : httpResponse , and: DataPointHTTPError.invalidStatus(statusCode: httpURLResponse.statusCode)))
                        }
                        return
                    }
                    
                    syncOnMain {
                        success(httpResponse)
                    }
                }
                
            }
            task.resume()
        } catch {
            self.errorCounter += 1
            failure(Failure(from: error))
        }
        
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

