//
//  OpaqueCollection.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

// A Collection with erased Collected types
// Used to perform operations that requires type erasure
public protocol OpaqueCollection{

    /// Stages the change of the item. (Equivalent to git staging)
    ///
    /// - Parameters:
    ///   - item: the item to stage
    func stage(_ item: Any)throws->()


    /// A remove function with type erasure to enable to perform dynamic cascading removal.
    //  used in ManagedModel+Erasure
    ///
    /// - Parameters:
    ///   - item: the item to erase
    ///   - commit: should we commit the erasure?
    func remove(_ item: Any , commit:Bool)throws->()

}
