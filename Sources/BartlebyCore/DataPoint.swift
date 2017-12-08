//
//  DataPoint.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

// Abstract class
open class DataPoint:SessionDelegate{

    // MARK: -

    public lazy var session:Session = Session(sessionDelegate: self)

    required public init(credentials:Credentials) {
        self.credentials = credentials
    }

    // MARK: SessionDelegate

    public var credentials: Credentials

    public var authenticationMethod: AuthenticationMethod = AuthenticationMethod.basicHTTPAuth

    public var scheme: Scheme = Scheme.https

    public var host: String = "NO_HOST"

    public var apiBasePath: String = "NO_BASE_API_PATH"

    
    // MARK: - Data integration and Operation Life Cycle


    /// The response.result shoud be stored in it DataPoint storage layer
    ///
    /// - Parameter response: the call Response
    public func integrateResponse<T>(_ response: Response<T>){
    }

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    public func deleteOperation<T,P>(_ operation: inout CallOperation<T,P>){
    }

    // MARK: -

    public func save(){
    }

}
