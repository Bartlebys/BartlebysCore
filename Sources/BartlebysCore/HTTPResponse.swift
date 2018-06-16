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


    /// Encodes the content to a String
    public var rawString: String? {
        return self.content != nil ? String(data: self.content!, encoding: Default.STRING_ENCODING) : nil
    }


    /// Encodes the content to a Pretty JSON
    public var prettyJSON: String? {
        guard let data = self.content else{
            return nil
        }
        do{
            let container = try JSONSerialization.jsonObject(with:data, options: JSONSerialization.ReadingOptions.allowFragments)
            let reEncodedJSON = try JSONSerialization.data(withJSONObject: container, options: JSONSerialization.WritingOptions.prettyPrinted)
            return String(data:reEncodedJSON,encoding: Default.STRING_ENCODING)
        }catch{
            return "\(error)"
        }
    }


    public init(metrics:Metrics, httpStatus:Status,content:Data?) {
        self.metrics = metrics
        self.httpStatus = httpStatus
        self.content = content
    }

}
