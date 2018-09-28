//
//  HTTProbe.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 30/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

open class HTTPProbe: ProbeDelegate{

    static fileprivate let _fileManager: FileManager = FileManager()

    public fileprivate (set) var relativeFolderPath: String

    public let classifier: String

    /// We use a serial queue for all our IO
    public static let IOQueue:DispatchQueue = DispatchQueue(label: "org.bartlebys.HTTPProbe", qos: .utility, attributes: [])

    public init(relativeFolderPath: String) {
        self.relativeFolderPath = relativeFolderPath
        self.classifier = URL(fileURLWithPath: relativeFolderPath).lastPathComponent
        HTTPProbe.IOQueue.async{
            do{
                try HTTPProbe._fileManager.createDirectory(at: self.folderURL, withIntermediateDirectories: true, attributes: nil)
            }catch{
                Logger.log(error, category: .warning)
            }
        }
    }

    fileprivate var _folderAsBeenTested:Bool = false

    public var folderURL:URL { return Paths.documentsDirectoryURL.appendingPathComponent("\(Paths.PROBES_FOLDER_NAME)\(self.relativeFolderPath)") }

    /// Cleans up all the serialized probes.
    public static func resetAll(then `do`: @escaping ()->()){
        HTTPProbe.IOQueue.async{
            let folder = Paths.documentsDirectoryURL.appendingPathComponent(Paths.PROBES_FOLDER_NAME)
            try? HTTPProbe._fileManager.removeItem(at:folder)
            try? HTTPProbe._fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            syncOnMain {
                `do`()
            }
        }
    }



    // MARK: - ProbeDelegate

    open func recordProbe(for request: URLRequest, response httpResponse: HTTPResponse) {
        let codableRequest: CodableURLRequest =  CodableURLRequest.from(request)
        let responseData:Data = (try? JSON.prettyEncoder.encode(httpResponse)) ?? "HTTPResponse serialization did fail".data(using:.utf8)!

        let trace: Trace = Trace(classifier: self.classifier,
                                 callCounter: httpResponse.callCounter,
                                 request: codableRequest,
                                 response: responseData,
                                 httpStatus: httpResponse.httpStatus.rawValue,
                                 sizeOfResponse: responseData.count)
        self.record(trace)
    }

    open func recordProbe<R>(for request: URLRequest, response httpResponse: DataResponse<R>) where R : Collectable, R : Decodable, R : Encodable {
        let codableRequest: CodableURLRequest =  CodableURLRequest.from(request)
        let responseData:Data = (try? JSON.prettyEncoder.encode(httpResponse)) ?? "DataResponse serialization did fail".data(using:.utf8)!

        let trace: Trace = Trace(classifier: self.classifier,
                                 callCounter: httpResponse.callCounter,
                                 request: codableRequest,
                                 response: responseData,
                                 httpStatus: httpResponse.httpStatus.rawValue,
                                 sizeOfResponse: httpResponse.content?.count ?? -1)
        self.record(trace)
    }

    open func recordProbe(for request: URLRequest, failure: Failure) {
        self.record(self.getTraceFor(request: request, failure: failure))
    }


    /// Returns a failure trace from a request and a failure state
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - failure: the failure state
    /// - Returns: the trace
    open func getTraceFor(request: URLRequest, failure: Failure) -> Trace{
        let codableRequest: CodableURLRequest =  CodableURLRequest.from(request)
        let responseData:Data = (try? JSON.prettyEncoder.encode(failure)) ?? "Failure serialization did fail".data(using:.utf8)!
        let trace: Trace = Trace(classifier: self.classifier,
                                 callCounter: failure.callCounter,
                                 request: codableRequest,
                                 response: responseData,
                                 httpStatus: failure.httpResponse?.httpStatus.rawValue ?? Status.undefined.rawValue,
                                 sizeOfResponse: failure.httpResponse?.content?.count ?? -1)
        return trace
    }


    // MARK : - Probe


    /// Records the trace
    ///
    /// - Parameter trace: the serialized trace
    public func record(_ trace:Trace){
        let data: Data = (try? JSON.prettyEncoder.encode(trace)) ?? "Trace serialization did fail".data(using: .utf8)!
        let fileName : String = "\(trace.callCounter.paddedString(6))"
        let url: URL = self.folderURL.appendingPathComponent("\(fileName)")
        HTTPProbe.IOQueue.async {
            do{
                try data.write(to: url)
            }catch{
                Logger.log(error)
            }
        }
    }

}
