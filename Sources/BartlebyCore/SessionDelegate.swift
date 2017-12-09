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

    /// Returns the data Point collections
    /// You can populate with concrete types (polymorphism)
    /// 
    /// Concrete return could be for example :
    ///     return [ events.asCollectionOfModel(), tags.asCollectionOfModel()]
    /// where
    ///     public var events: ObjectCollection<Event> = ObjectCollection<Event>()
    ///
    /// - Returns: the data Point model collections
     func getCollections()->[ObjectCollection<Model>]

    /// The credentials should generaly not change during the session
    var credentials:Credentials { get set }

    /// The authentication method
    var authenticationMethod: AuthenticationMethod { get }

    /// The current Scheme .https is a must
    var scheme:Schemes { get }

    // The current Host: e.g demo.bartlebys.org
    var host:String { get }

    // The api base path: e.g /api/v1
    var apiBasePath: String { get }

    // MARK: - URL request

    ///  Returns the configured URLrequest
    ///
    /// - Parameters:
    ///   - path: the path e.g: users/
    ///   - queryString: eg: &page=0&size=10
    ///   - method: the http Method
    /// - Returns:  the URL request
    /// - Throws: url issues
    func requestFor( path: String, queryString: String, method: HTTPMethod) throws -> URLRequest

    /// Returns the configured URLrequest
    ///
    /// - Parameters:
    ///   - path: the path e.g: users/
    ///   - queryString: eg: &page=0&size=10
    ///   - method: the http Method
    /// - Returns: the URL request
    /// - Throws: issue on URL creation or Parameters deserialization
    func requestFor<P:Payload>( path: String, queryString: String, method: HTTPMethod , parameter:P)throws -> URLRequest


    /// Returns the relevent request for a given call Operation
    ///
    /// - Parameter operation: the operation
    /// - Returns: the URL request
    /// - Throws: issue on URL creation and operation Parameters serialization
    func requestFor<T:Codable,P>(_ operation: CallOperation<T,P>) throws -> URLRequest


    // MARK: - Response & CallOperation

    /// The response.result shoud be stored in it DataPoint storage layer
    ///
    /// - Parameter response: the call Response
    func integrateResponse<T>(_ response:Response<T>)

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    func deleteOperation<T,P>(_ operation: CallOperation<T,P>)
}
