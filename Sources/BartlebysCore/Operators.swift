//
//  Operators.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 20/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation


// The `=? operator allows simplify optional assignements :
//  `a = b ?? a` can be written : `a =? b`
infix operator =?: AssignmentPrecedence

public func =?<T> ( left: inout T?, right: T? ){
    left = right ?? left
}

public func =?<T> ( left: inout T, right: T? ){
    left = right ?? left
}
