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
public protocol IndistinctCollection:UniversalType,Identifiable{

    /// References the element into the dataPoint registry
    ///
    /// - Parameter item: the item
    func reference<T:  Codable & Collectable >(_ item:T)

    /// Removes the item from the collection
    ///
    /// - Parameter item: the item
    func removeItem<C: Codable & Collectable>(_ item: C)throws->()

    /// Called when the collection or one of its member has Changed
    func didChange()

    /// Used to access to call operations
    /// Returns the call operation if revelent
    /// If the result is not null it means that the collection is a collection of CallOperation
    var dynamicCallOperations:[CallOperationProtocol]?{ get }
}
