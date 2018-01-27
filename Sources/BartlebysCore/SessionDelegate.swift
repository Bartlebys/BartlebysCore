//
//  SessionDelegate.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//
import Foundation

public enum AuthenticationMethod {
    case basicHTTPAuth
}


/// Base Session Delegate check also DataPointProtocol
public protocol SessionDelegate {

    // We can use any coding dialect
    // That may be different than the storage's
    var operationsCoder:ConcreteCoder { get set }

    var storage:StorageProtocol { get set }

    /// The credentials should generaly not change during the session
    var credentials:Credentials { get set }

    /// The authentication method
    var authenticationMethod: AuthenticationMethod { get }

    /// The current Scheme .https is a must
    var scheme:Schemes { get }


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

    // MARK: - CallOperation


    /// Provisions the operation in the relevent collection
    ///
    /// - Parameter operation: the call operation
    /// - Throws: error if the collection hasn't be found
    func provision<P, R>(_ operation:CallOperation<P, R>) throws

    /// Returns the relevent request for a given call Operation
    ///
    /// - Parameter operation: the operation
    /// - Returns: the URL request
    /// - Throws: issue on URL creation and operation Parameters serialization
    func requestFor<P, R>(_ operation: CallOperation<P, R>) throws -> URLRequest

    
    /// The response.result shoud be stored in it DataPoint storage layer
    ///
    /// - Parameter response: the call Response
    func integrateResponse<R>(_ response:DataResponse<R>)

    /// Implements the concrete Removal of the CallOperation on success
    ///
    /// - Parameter operation: the targeted Call Operation
    /// - Throws: throws error is the call operation or its collection is not found
    func deleteCallOperation<P, R>(_ operation: CallOperation<P, R>) throws

    /// Implements the faulting logic
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - error: the error
    func callOperationExecutionDidFail<P, R>(_ operation: CallOperation<P, R>, error:Error?)

    /// Execute the next Pending Operations for a given the CallSequence Name
    func executeNext(from callSequenceName:CallSequence.Name)

    /// Used to determine if we should destroy some Operations
    /// Returns a quota of operation to preserve for each sequence.
    /// If the value is over the quota the older operations are destroyed
    /// By default Bartleby "would prefer not to" that's why the preservationQuota respond Int.max by defaults
    ///
    /// - Parameter for: the CallSequence name
    /// - Returns: the max number of call operations.
    func preservationQuota<P,R>(callOperationType:CallOperation<P,R>.Type)->Int


}
