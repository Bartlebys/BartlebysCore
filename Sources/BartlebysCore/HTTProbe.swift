//
//  HTTProbe.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 30/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public class HTTProbe: ProbeDelegate{

    public var folderPath: String

    /// We use a serial queue for all our IO
    public fileprivate(set) var IOQueue:DispatchQueue = DispatchQueue(label: "org.bartlebys.HTTPProbe", qos: .utility, attributes: [])

    init(folderPath: String) {
        self.folderPath = folderPath
    }


    /// Cleans up all the serialized probes.
    public func reset(){
        self.IOQueue.async {
            let fm = FileManager()
            try? fm.removeItem(atPath: self.folderPath)
        }
    }

    // MARK: - ProbeDelegate

    public func recordProbe(for request: URLRequest, response httpResponse: HTTPResponse) {
        let codableRequest: CodableURLRequest =  CodableURLRequest.from(request)
        let responseData:Data = (try? JSON.prettyEncoder.encode(httpResponse)) ?? "HTTPResponse serialization did fail".data(using:.utf8)!
        let trace: Trace = Trace.init(callCounter: httpResponse.callCounter, request: codableRequest, response: responseData)
        self.record(trace)
    }

    public func recordProbe<R>(for request: URLRequest, response httpResponse: DataResponse<R>) where R : Collectable, R : Decodable, R : Encodable {
        let codableRequest: CodableURLRequest =  CodableURLRequest.from(request)
        let responseData:Data = (try? JSON.prettyEncoder.encode(httpResponse)) ?? "DataResponse serialization did fail".data(using:.utf8)!
        let trace: Trace = Trace.init(callCounter: httpResponse.callCounter, request: codableRequest, response: responseData)
        self.record(trace)
    }

    public func recordProbe(for request: URLRequest, failure: Failure) {
        let codableRequest: CodableURLRequest =  CodableURLRequest.from(request)
        let responseData:Data = (try? JSON.prettyEncoder.encode(failure)) ?? "Failure serialization did fail".data(using:.utf8)!
        let trace: Trace = Trace.init(callCounter: failure.callCounter, request: codableRequest, response: responseData)
        self.record(trace)
    }


    // MARK : - Probe


    /// Records the trace
    ///
    /// - Parameter trace: the serialized trace
    public func record(_ trace:Trace){
        let urlMethod: String = trace.request.httpMethod ?? "NO_METHOD"
        let urlString: String = trace.request.url?.absoluteString ?? "NO_URL"
        let data: Data = (try? JSON.prettyEncoder.encode(trace)) ?? "Trace serialization did fail".data(using: .utf8)!
        let fileName : String = "\(trace.callCounter.paddedString(6)).\(urlMethod).\(urlString).json"
        let url: URL = URL(fileURLWithPath: self.folderPath+"/" + fileName )
        self.IOQueue.async {try? data.write(to: url) }
    }

}
