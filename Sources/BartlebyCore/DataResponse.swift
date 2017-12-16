//
//  Response.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public class DataResponse<T> : HTTPResponse where T : Codable & Collectible {
    
    public var result: Array<T>

    required public init(result: Array<T>) {
        self.result = result
        super.init()
    }
}

