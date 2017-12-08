//
//  Response.swift
//  LPSynciOS
//
//  Created by Laurent Morvillier on 08/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public struct Response<T> where T : Codable {
    
    public var httpStatus: Status
    public var content: Data?
    public var result: Array<T>
    public var error: Error?
    public var metrics: Metrics
    
    public var resultString: String? {
        return self.content != nil ? String(data: self.content!, encoding: .utf8) : ""
    }
}
