//
//  Trace.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 30/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


/// Used by HTTPProbe to serialize the requests and responses.
public struct Trace:Codable {

    // You can use the claasifier to split traces for example per session (runUID)
    public var classifier: UID? = Default.NO_UID

    // The request call counter
    public let callCounter: Int

    // The resquest call
    public let request: CodableURLRequest

    // The response
    public let response: Data


    /// The constructor
    ///
    /// - Parameters:
    ///   - callCounter: the call counter
    ///   - request: the associated request state
    ///   - response: the HTTP response.
    public init ( callCounter: Int, request: CodableURLRequest, response: Data){
        self.callCounter = callCounter
        self.request = request
        self.response = response
    }


    /// Loads the Trace from a file.
    ///
    /// - Parameter url: the URL
    /// - Returns: the casted trace
    /// - Throws: exceptions on decoding & deserialization
    public static func from(_ url: URL) throws -> Trace{
        let traceData = try Data.init(contentsOf: url)
        return try JSON.decoder.decode(Trace.self, from: traceData)
    }
}
