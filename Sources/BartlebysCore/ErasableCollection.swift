//
//  ErasableCollection.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 02/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// A Collection with erased Collected types
// Used to perform operations that requires type erasure
public protocol ErasableCollection{

    /// Removes the item from the collection
    /// The implementation should throw CollectionOfError.collectedTypeMustBeTolerent
    /// if the item is not tolerent.
    ///
    /// - Parameter item: the item
    func remove<C: Codable & Collectible>(_ item: C)throws->()

}
