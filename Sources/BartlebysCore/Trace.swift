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

    let callCounter: Int
    let request: CodableURLRequest
    let response: Data

}
