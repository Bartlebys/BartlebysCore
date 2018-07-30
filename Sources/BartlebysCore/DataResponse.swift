//
//  Response.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public class DataResponse<T> : HTTPResponse where T : Codable & Collectable {

    // The result
    public var result: Array<T>

    required public init(result: Array<T>,content:Data?, metrics:Metrics, httpStatus:Status) {
        self.result = result
        super.init(metrics: metrics, httpStatus: httpStatus, content: content)
    }

    // MARK: - Codable

    public enum DataResponseCodingKeys: String,CodingKey{
        case result
        case httpStatus
        case content
    }

    public required init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: DataResponseCodingKeys.self)
        self.result = try values.decode(Array<T>.self,forKey:.result)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to:encoder)
        var container = encoder.container(keyedBy: DataResponseCodingKeys.self)
        try container.encode(self.result,forKey:.result)
    }

}

