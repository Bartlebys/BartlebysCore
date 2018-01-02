//
//  Initializable.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 10/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation


/// Guarantees that any instance can be initialized by init()
/// You can adopt `Initializable` to force the instance to have default value on any required properties
public protocol Initializable{
    init()
}
