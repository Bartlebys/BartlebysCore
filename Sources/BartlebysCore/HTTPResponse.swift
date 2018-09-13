//
//  HTTPResponse.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class HTTPResponse: Codable {

    public var metrics: Metrics?

    public var httpStatus: Status = Status.undefined

    /// A dictionary containing all the HTTP header fields of the
    /// receiver.
    public var allHTTPHeaderFields: [String : String]?

    public var content: Data?


    /// The accessor to the call counter.
    public var callCounter:Int { return self.metrics?.callCounter ?? -1 }

    /// Encodes the content to a String
    public var rawString: String? {
        return self.content != nil ? String(data: self.content!, encoding: Default.STRING_ENCODING) : nil
    }

    /// Encodes the content to a Pretty JSON
    public var prettyJsonContent: String? {
        guard let data = self.content else{
            return nil
        }
        do{
            let container:Any = try JSONSerialization.jsonObject(with:data, options: JSONSerialization.ReadingOptions.allowFragments)
            let reEncodedJSON:Data = try JSONSerialization.data(withJSONObject: container, options: JSONSerialization.WritingOptions.prettyPrinted)
            return String(data:reEncodedJSON,encoding: Default.STRING_ENCODING)
        }catch{
            return "\(error)"
        }
    }


    public init(metrics: Metrics, httpStatus: Status, allHTTPHeaderFields: [String:String]? , content: Data?) {
        self.metrics = metrics
        self.httpStatus = httpStatus
        self.allHTTPHeaderFields = allHTTPHeaderFields
        self.content = content
    }


    // MARK: - Codable


    public enum HTTPResponseCodingKeys: String,CodingKey{
        case metrics
        case httpStatus
        case allHTTPHeaderFields
        case content
    }

    public required  init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: HTTPResponseCodingKeys.self)
        self.metrics = try values.decode(Metrics.self,forKey:.metrics)
        let intStatus = try values.decode(Int.self,forKey:.httpStatus)
        if let httpStatus:Status = Status(rawValue:intStatus){
            self.httpStatus = httpStatus
        }
        self.allHTTPHeaderFields = try values.decodeIfPresent([String : String].self,forKey:.allHTTPHeaderFields)
        self.content = try values.decodeIfPresent(Data.self,forKey:.content)

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: HTTPResponseCodingKeys.self)
        try container.encode(self.metrics, forKey: .metrics)
        try container.encode(self.httpStatus.rawValue, forKey: .httpStatus)
        try container.encodeIfPresent(self.allHTTPHeaderFields,forKey:.allHTTPHeaderFields)
        try container.encodeIfPresent(self.content,forKey:.content)
    }

}
