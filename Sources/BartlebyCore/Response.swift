//
//  Response.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


public class HTTPResponse {
    
    public var httpStatus: Status = Status.undefined
    public var content: Data?
    public var error: Error?
    public var metrics: Metrics = Metrics()

    public var resultString: String? {
        return self.content != nil ? String(data: self.content!, encoding: .utf8) : ""
    }
    
    init() { }
    
}

public class Response<T> : HTTPResponse where T : Codable & Collectible {
    
    public var result: Array<T>

    required public init(result: Array<T>) {
        self.result = result
        super.init()
    }
}

