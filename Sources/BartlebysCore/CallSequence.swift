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

}
