//
//  UniversalType.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da Silva on 04/12/2017.
//  Copyright © 2017 B. All rights reserved.
//

import Foundation

public protocol UniversalType {

    /// Collection name must be unique
    /// It serves as dynamic identifier and is used by the file system
    static var collectionName : String { get }


    /// The dynamic alias to static collectionName
    var d_collectionName : String { get }


    /// The type as a String
    static var typeName : String { get }

}
