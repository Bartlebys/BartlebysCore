//
//  CallSequence.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


/// Should be implemented by any Concrete CallSequence
public protocol ConcreteCallSequence {

    /// Used to truncate cancellable Operation
    /// Returns a quota of operation to preserve for each sequence.
    /// If the value is over the quota the older matching cancelable operation would be deleted
    ///
    /// - Parameter for: the CallSequence name
    /// - Returns: the max number of call operations.
    func preservationQuota<P,R>(callOperationType:CallOperation<P,R>.Type)->Int

}


/// The base CallSequence to by used to implement a Concrete 
open class CallSequence {

    public enum Name:String{
        case data // general data sequence
        case uploads // used for files uploads
        case downloads // used for files downloads
    }

    var name:CallSequence.Name

    init(named:CallSequence.Name) {
        self.name = named
    }

}


/// The default call Sequence, "would prefer not to"... delete any CallOperation
public class DefaultCallSequence:CallSequence, ConcreteCallSequence{

    
    /// Used to truncate cancellable Operation
    /// Returns a quota of operation to preserve for each sequence.
    /// If the value is over the quota the older matching cancelable operation would be deleted
    ///
    /// - Parameter for: the CallSequence name
    /// - Returns: the max number of call operations.
    public func preservationQuota<P,R>(callOperationType:CallOperation<P,R>.Type)->Int{
        return Int.max
    }
}
