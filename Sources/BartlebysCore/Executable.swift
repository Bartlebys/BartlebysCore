//
//  Executable.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 26/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public protocol Executable {

    var scheduledOrderOfExecution:Int{ get }

    func execute(in:Session)

}
