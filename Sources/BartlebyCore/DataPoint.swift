//
//  DataPoint.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

// Abstract class
open class DataPoint : SessionDelegate {

    // MARK: -

    public lazy var session:Session = Session(sessionDelegate: self)

    required public init(credentials:Credentials) {
        self.credentials = credentials
    }

    // MARK: SessionDelegate

    open var credentials: Credentials

    open var authenticationMethod: AuthenticationMethod = AuthenticationMethod.basicHTTPAuth

    open var scheme: Schemes = Schemes.https

    open var host: String = "NO_HOST"

    open var apiBasePath: String = "NO_BASE_API_PATH"

    // MARK: - URLRequest Provider
    
    open func baseRequest(with url:URL, method: HTTPMethod) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return request
    }
    
    // MARK: - Data integration and Operation Life Cycle


    /// The response.result shoud be stored in it DataPoint storage layer
    ///
    /// - Parameter response: the call Response
    open func integrateResponse<T>(_ response: Response<T>){
    }

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    open func deleteOperation<T,P>(_ operation: CallOperation<T,P>){
    }

    // MARK: -

    open func save(){
    }

}
