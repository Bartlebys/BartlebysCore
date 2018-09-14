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
// This protocol is implemented by the Collection Management layer (for example in BartlebyKit)
public protocol ManagedCollection: IndistinctCollection{

    /// Stages the change of the item. (Equivalent to git staging)
    ///
    /// - Parameters:
    ///   - item: the item to stage
    func stageItem<C:Codable & Collectable>(_ item: C)throws->()


    /// A remove function with type erasure to enable to perform dynamic cascading removal.
    /// 
    /// - Parameters:
    ///   - item: the item to erase
    ///   - commit: should we commit the erasure?
    func removeItem<C:Codable & Collectable>(_ item: C , commit:Bool)throws->()

}
