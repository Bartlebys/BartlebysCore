//
//  Trace.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 30/07/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


/// Used by HTTPProbe to serialize the requests and responses.
public struct Trace: Codable {

    // You can use the claasifier to split traces per session
    public var classifier: UID = Default.NO_UID

    // The request call counter
    public let callCounter: Int

    // The resquest call
    public let request: CodableURLRequest

    // The response
    public let response: Data

    // The HTTP status
    public let httpStatus: Int

    // The size of the response expressed in Bytes
    public let sizeOfResponse: Int

    /// Loads the Trace from a file.
    ///
    /// - Parameter url: the URL
    /// - Returns: the casted trace
    /// - Throws: exceptions on decoding & deserialization
    public static func from(_ url: URL) throws -> Trace{
        let traceData = try Data.init(contentsOf: url)
        return try JSON.decoder.decode(Trace.self, from: traceData)
    }


    /// Encodes the response to a Pretty JSON
    public var prettyJsonResponse: String? {
        do{
            let container:Any = try JSONSerialization.jsonObject(with: self.response, options: JSONSerialization.ReadingOptions.allowFragments)
            let reEncodedJSON: Data = try JSONSerialization.data(withJSONObject: container, options: JSONSerialization.WritingOptions.prettyPrinted)
            return String(data:reEncodedJSON,encoding: Default.STRING_ENCODING)
        }catch{
            return "\(error)"
        }
    }
}
