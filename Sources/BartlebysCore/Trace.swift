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

    public let callCounter: Int
    public let request: CodableURLRequest
    public let response: Data


    public static func from(_ url: URL) throws -> Trace{
        let traceData = try Data.init(contentsOf: url)
        return try JSON.decoder.decode(Trace.self, from: traceData)
    }
}
