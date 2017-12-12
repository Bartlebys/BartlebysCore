//
//  HTTPResponse.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
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
