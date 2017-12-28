//
//  Collectible.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public protocol Collectible : UniversalType {

    // Universally Unique identifier (check Globals.swift for details on the primary key MODELS_PRIMARY_KEY)
    var id:String { get set }

    // The Associated collected type is equal the Collectible type
    associatedtype CollectedType


    /// Registers its collection reference
    ///
    /// - Parameter collection: the collection
    func setCollection<CollectedType>(_ collection:CollectionOf<CollectedType>)


    /// Returns the collection
    ///
    /// - Returns: the collection
    func getCollection<CollectedType>()->CollectionOf<CollectedType>
}

