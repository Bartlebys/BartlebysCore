//
//  CallOperations.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 01/05/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

/// This struct should be used to execute efficiently multiple CallOperations.
public struct CallOperations<P,R> where P : Payload, R : Result & Collectable{

    let operations:[CallOperation<P,R>]

    let dataPoint:DataPoint

    public func execute() -> () {
        /// Uses the optimized execution model for multiple CallOperations
        self.dataPoint.execute(self.operations)
    }

}
