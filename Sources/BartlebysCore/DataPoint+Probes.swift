//
//  DataPoint+Probes.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public protocol ProbeDelegate {

    func recordProbe(for request: URLRequest, response httpResponse: HTTPResponse)
    func recordProbe<R>(for request: URLRequest, response httpResponse: DataResponse<R>)
    func recordProbe(for request: URLRequest, failure: Failure)
    
}

extension DataPoint{


    /// Probes If necessary the response for analysis
    /// Then relays to the success closure.
    ///
    /// - Parameters:
    ///   - request: the original request
    ///   - httpResponse: the response
    ///   - relay: the succes closure
    public func probe(request: URLRequest, response httpResponse: HTTPResponse, relay: @escaping (_ completion: HTTPResponse) -> ()) {
        self.probeDelegate?.recordProbe(for: request, response: httpResponse)
        relay(httpResponse)
    }


    /// Probes If necessary the response for analysis
    /// Then relays to the success closure.
    ///
    /// - Parameters:
    ///   - request: the original request
    ///   - httpResponse: the response
    ///   - relay: the succes closure
    public func probe<R>(request: URLRequest, response dataResponse: DataResponse<R>, relay: @escaping (_ completion: DataResponse<R>) -> ()) {
        self.probeDelegate?.recordProbe(for: request, response: dataResponse)
        relay(dataResponse)
    }


    /// Probes if necessary the response for analysis
    /// Then relay the failure to the failure closure.
    ///
    /// - Parameters:
    ///   - request: the original request
    ///   - failure: the failure description
    ///   - relay: the failure closure
    public func probe(request: URLRequest, failure: Failure, relay: @escaping (_ completion: Failure) -> ()) {
        self.probeDelegate?.recordProbe(for: request, failure: failure)
        relay(failure)
    }

}
