//
//  DataPointProtocol.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


public protocol DataPointProtocol:SessionDelegate{

    // The current Host: e.g demo.bartlebys.org
    var host:String { get }

    // The api base path: e.g /api/v1
    var apiBasePath: String { get }
    
}
