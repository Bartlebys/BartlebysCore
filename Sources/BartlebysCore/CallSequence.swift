//
//  CallSequence.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


/// CallSequence.Name are used to segment call operations.
/// Check DataPoint for usage sample
public struct CallSequence {

    public typealias Name = String

    public static let data :CallSequence.Name = "data"// general data sequence
    public static let uploads:CallSequence.Name = "uploads" // used for files uploads
    public static let downloads:CallSequence.Name = "downloads" // used for files downloads

    // The name of the CallSequence
    public var name:Name

    // The bunch size define the number of parallel call operations in a call Sequence
    // The execution order is always garanted (but not the result order if bunchSize > 1)
    public var bunchSize:Int = 1

    public init(name: Name, bunchSize: Int){
        self.name = name
        self.bunchSize = bunchSize
    }

}
