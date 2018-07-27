//
//  DataPoint+Probes.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public protocol ProbeDelegate {

    func recordProbe(_ httpResponse: HTTPResponse)
    func recordProbe<R>(_ httpResponse: DataResponse<R>)
    func recordProbe(_ failure: Failure)
    
}

extension DataPoint{


    /// Probes If necessary the response for analysis
    /// Then relays to the success closure.
    ///
    /// - Parameters:
    ///   - httpResponse: the response
    ///   - relay: the succes closure
    public func probe(_ httpResponse: HTTPResponse, relay: @escaping (_ completion: HTTPResponse) -> ()) {
        self.probeDelegate?.recordProbe(httpResponse)
        relay(httpResponse)
    }


    /// Probes If necessary the response for analysis
    /// Then relays to the success closure.
    ///
    /// - Parameters:
    ///   - httpResponse: the response
    ///   - relay: the succes closure
    public func probe<R>(_ dataResponse: DataResponse<R>, relay: @escaping (_ completion: DataResponse<R>) -> ()) {
        self.probeDelegate?.recordProbe(dataResponse)
        relay(dataResponse)
    }


    /// Probes if necessary the response for analysis
    /// Then relay the failure to the failure closure.
    ///
    /// - Parameters:
    ///   - failure: the failure description
    ///   - relay: the failure closure
    public func probe(_ failure: Failure, relay: @escaping (_ completion: Failure) -> ()) {
        self.probeDelegate?.recordProbe(failure)
        relay(failure)
    }

}
