//
//  CodableURLRequest.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 30/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public class CodableURLRequest: Codable {

    /// The URL of the receiver.
    public var url: URL?

    /// The HTTP request method of the receiver.
    public var httpMethod: String?

    /// A dictionary containing all the HTTP header fields of the
    /// receiver.
    public var allHTTPHeaderFields: [String : String]?

    /// This data is sent as the message body of the request, as
    /// in done in an HTTP POST request.
    public var httpBody: Data?


    /// Creates an CodableURLRequest from an URL Request
    ///
    /// - Parameter urlRequest: the Request
    /// - Returns: the codable Request
    static func from(_ urlRequest: URLRequest) -> CodableURLRequest{
        let request = CodableURLRequest()
        request.url = urlRequest.url
        request.httpMethod = urlRequest.httpMethod
        request.allHTTPHeaderFields = urlRequest.allHTTPHeaderFields
        request.httpBody = urlRequest.httpBody
        return request
    }

    public init() {}

    // MARK: - Codable

    public enum CodableURLRequestCodingKeys: String,CodingKey{
        case url
        case httpMethod
        case allHTTPHeaderFields
        case httpBody
    }

    public required  init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: CodableURLRequestCodingKeys.self)
        self.url = try values.decodeIfPresent(URL.self,forKey:.url)
        self.httpMethod = try values.decodeIfPresent(String.self,forKey:.httpMethod)
        self.allHTTPHeaderFields = try values.decodeIfPresent([String : String].self,forKey:.allHTTPHeaderFields)
        self.httpBody = try values.decodeIfPresent(Data.self,forKey:.httpBody)

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodableURLRequestCodingKeys.self)
        try container.encodeIfPresent(self.url, forKey: .url)
        try container.encodeIfPresent(self.httpMethod, forKey: .httpMethod)
        try container.encodeIfPresent(self.allHTTPHeaderFields,forKey:.allHTTPHeaderFields)
        try container.encodeIfPresent(self.httpBody,forKey:.httpBody)
    }

}
