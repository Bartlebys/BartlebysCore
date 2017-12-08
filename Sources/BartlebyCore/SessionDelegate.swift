//
//  SessionDelegate.swift
//  LPSynciOS
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public enum AuthenticationMethod {
    case basicHTTPAuth
}

public protocol SessionDelegate {

    var credentials:Credentials { get set }

    var authenticationMethod: AuthenticationMethod { get }

    var scheme:Schemes { get }

    var host:String { get }

    var apiBasePath: String { get }

    func baseRequest(with url:URL, method: HTTPMethod) -> URLRequest

    /// The response.result shoud be stored in it DataPoint storage layer
    ///
    /// - Parameter response: the call Response
    func integrateResponse<T>(_ response:Response<T>)

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    func deleteOperation<T,P>(_ operation: CallOperation<T,P>)
}
