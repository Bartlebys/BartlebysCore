//
//  DataPoint+Execution.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 12/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

extension DataPoint{

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
                            let decoded = try self.operationsCoder.decodeArrayOf(R.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            let dataResponse = DataResponse(result: decoded, content: data, metrics: metrics, httpStatus: httpResponse.statusCode.status())
                            syncOnMain {
                                success(dataResponse)
                            }
                        }else{
                            let decoded = try self.operationsCoder.decode(R.self, from: data)
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            let dataResponse = DataResponse(result: [decoded], content: data, metrics: metrics, httpStatus: httpResponse.statusCode.status())
                            syncOnMain {
                                success(dataResponse)
                            }
                        }
                    } catch {
                        syncOnMain {
                            let dataResponse = DataResponse(result:Array<R>(), content: data, metrics: metrics, httpStatus: httpResponse.statusCode.status())
                            failure(Failure(from : dataResponse, and: error))
                        }
                    }
                } else {
                    // There is no data
                    if let error = error {
                        syncOnMain {
                            let dataResponse = DataResponse(result:Array<R>(), content: nil, metrics: metrics, httpStatus: httpResponse.statusCode.status())
                            failure(Failure(from : dataResponse , and: error))
                        }
                    } else {
                        syncOnMain {
                            metrics.serializationDuration = AbsoluteTimeGetCurrent() - serverHasRespondedTime
                            let dataResponse: DataResponse = DataResponse(result: Array<R>(),content: nil,metrics: metrics, httpStatus: httpResponse.statusCode.status())
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

            if let error = error {
                syncOnMain {
                    let fileError = FileOperationError.errorOn(filePath: localFilePath, error: error)
                    failure(Failure(from: fileError))
                }
            } else if let httpURLResponse = response as? HTTPURLResponse {

                let httpResponse = HTTPResponse(metrics: metrics, httpStatus: httpURLResponse.statusCode.status(), content: nil)

                guard let tempURL = temporaryURL else {
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
                    syncOnMain {
                        failure(Failure(from: httpResponse, and: error))
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
            let localFileURL = try localFilePath.absoluteFileURL()

            let task = URLSession.shared.uploadTask(with: request, fromFile: localFileURL) { (data, response, error) in

                let serverHasRespondedTime = AbsoluteTimeGetCurrent()
                metrics.requestDuration = serverHasRespondedTime - (self.startTime + metrics.elapsed)

                if let error = error {
                    syncOnMain {
                        let fileError = FileOperationError.errorOn(filePath: localFilePath, error: error)
                        failure(Failure(from: fileError))
                    }
                } else if let httpURLResponse = response as? HTTPURLResponse {
                    let httpResponse = HTTPResponse(metrics: metrics, httpStatus: httpURLResponse.statusCode.status(), content: nil)

                    switch httpURLResponse.statusCode {
                    case 200...299:
                        syncOnMain {
                            success(httpResponse)
                        }
                    default:
                        syncOnMain {
                            failure(Failure(from: httpResponse))
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
