//
//  DataPoint.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public enum DataPointError:Error{
    case invalidURL
    case voidURLRequest
}

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


    ///  Returns the configured URLrequest
    ///  This func is public not open
    /// - Parameters:
    ///   - path: the path e.g: users/
    ///   - queryString: eg: &page=0&size=10
    ///   - method: the http Method
    /// - Returns:  the URL request
    /// - Throws: url issues
    open func requestFor( path: String, queryString: String, method: HTTPMethod) throws -> URLRequest{

        guard let url = URL(string: self.scheme.rawValue + self.host + path + queryString) else {
            throw DataPointError.invalidURL
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.rawValue

        switch self.authenticationMethod {
        case .basicHTTPAuth:
             let loginString = "\(self.credentials.username):\(self.credentials.password)"
             if let loginData: Data = loginString.data(using: .utf8) {
                let base64LoginString: String = loginData.base64EncodedString()
                request.setValue(base64LoginString, forHTTPHeaderField: "Authorization")
             }
        }

        return request
    }


    /// Returns the configured URLrequest
    ///
    /// - Parameters:
    ///   - path: the path e.g: users/
    ///   - queryString: eg: &page=0&size=10
    ///   - method: the http Method
    /// - Returns: the URL request
    /// - Throws: issue on URL creation or Parameters deserialization
    open func requestFor<P:Payload>( path: String, queryString: String, method: HTTPMethod , parameter:P)throws -> URLRequest{

        var request = try self.requestFor(path: path, queryString: queryString, method: method)

        if !(parameter is VoidPayload) {
            // By default we encode the JSON parameter in the body
            // If the Parameter is not void
            request.httpBody = try JSONEncoder().encode(parameter)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        Logger.log("\(request.url?.absoluteString ?? "NO_URL" )", category: Logger.Categories.temporary)
        Logger.log("parameter = \(parameter)", category: Logger.Categories.temporary)

        return request
    }

    /// Returns the relevent request for a given call Operation
    ///
    /// - Parameter operation: the operation
    /// - Returns: the URL request
    /// - Throws: issue on URL creation and operation Parameters serialization
    open func requestFor<T:Codable,P>(_ operation: CallOperation<T,P>) throws -> URLRequest{
        throw DataPointError.voidURLRequest
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
