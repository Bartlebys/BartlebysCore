//
//  Collectable.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public protocol Incorporated{

    // The reference to the dataPoint
    var dataPoint:DataPoint? { get }

}

public protocol Collectable : Hashable, Incorporated, UniversalType, Identifiable, Initializable {

    // Universally Unique identifier (check Globals.swift for details on the primary key MODELS_PRIMARY_KEY)
    var id: UID { get set }

    // The Associated "CollectedType" is the Collectable type
    associatedtype CollectedType

    /// Sets the dataPoint Reference
    ///
    /// - Parameter dataPoint: the dataPoint
    func setDataPoint(_ dataPoint: DataPoint)

    /// Registers its collection reference
    ///
    /// - Parameter collection: the collection
    func setCollection<CollectedType>(_ collection: CollectionOf<CollectedType>)


    /// Returns the collection
    ///
    /// - Returns: the collection
    func getCollection<CollectedType>() -> CollectionOf<CollectedType>


    /// The type erased acceessor to a collection that support reference, remove & didChange
    var indistinctCollection: IndistinctCollection? { get }

}
