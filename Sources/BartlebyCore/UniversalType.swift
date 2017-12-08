//
//  UniversalType.swift
//  LPSync
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public protocol UniversalType {
    
    static var collectionName : String { get }
    
    var d_collectionName : String { get }

    static var typeName : String { get }

}
