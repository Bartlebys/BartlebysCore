//
//  HTTPResponse.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class HTTPResponse {

    public var metrics: Metrics?
    public var httpStatus: Status = Status.undefined
    public var content: Data?
    
    public var resultString: String? {
        return self.content != nil ? String(data: self.content!, encoding: .utf8) : ""
    }

    public init(metrics:Metrics, httpStatus:Status,content:Data?) {
        self.metrics = metrics
        self.httpStatus = httpStatus
        self.content = content
    }
    
}
