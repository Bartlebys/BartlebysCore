//
//  Failure.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


public enum FailureError:Error{
    case message(_ message: String)
}

public class Failure: Codable {

    public var httpResponse: HTTPResponse?
    public var error: Error?

    public init(from error:Error) {
        self.error = error
    }

    public init(from response: HTTPResponse) {
        self.httpResponse = response
        self.error = nil
    }

    public init(from response: HTTPResponse, and error: Error?) {
        self.httpResponse = response
        self.error = error
    }

    /// The accessor to the call counter.
    public var callCounter: Int { return self.httpResponse?.callCounter ?? -1 }


    // MARK: - Codable


    public enum FailureCodingKeys: String,CodingKey{
        case httpResponse
        case error
    }

    public required init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: FailureCodingKeys.self)
        self.httpResponse = try values.decode(HTTPResponse.self,forKey:.httpResponse)
        // We decode/encode the error to a FailureError via a String
        let stringError = try values.decode(String.self,forKey:.error)
        self.error = FailureError.message(stringError)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FailureCodingKeys.self)
        try container.encode(self.httpResponse, forKey: .httpResponse)
        // We decode/encode the error to a FailureError via a String
        try container.encodeIfPresent(self.error?.localizedDescription, forKey: .error)
    }
}
