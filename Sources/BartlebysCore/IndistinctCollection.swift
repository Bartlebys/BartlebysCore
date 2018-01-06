//
//  IndistinctCollection.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 02/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// A Collection with erased Collected types
// Can be Used to perform operations that requires type erasure
public protocol IndistinctCollection:UniversalType{

    /// References the element into the dataPoint registry
    ///
    /// - Parameter item: the item
    func reference<T:  Codable & Collectable & Tolerent >(_ item:T)

    /// Removes the item from the collection
    /// The implementation should throw CollectionOfError.collectedTypeMustBeTolerent
    /// if the item is not tolerent.
    ///
    /// - Parameter item: the item
    func removeItem<C: Codable & Collectable>(_ item: C)throws->()

    /// Called when the collection or one of its member has Changed
    func didChange()
}
