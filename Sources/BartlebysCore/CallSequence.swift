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
public class CallSequence {

    public enum Name:String{
        case data // general data sequence
        case uploads // used for files uploads
        case downloads // used for files downloads
    }

}
