//
//  Relational.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol Relational:Identifiable, Incorporated{


    // MARK: - Relationships Declaration

    /// An Object enters in a free relation Ship with another
    ///
    /// - Parameters:
    ///   - object:  object: the owned object
    func declaresFreeRelationShip(to object:Relational)


    /// The owner declares it properties
    /// Both relation are setup owns, and owned
    ///
    /// - Parameters:
    ///   - object:  object: the owned object
    func declaresOwnership(of object:Relational)


    /// Add a relation to another object
    /// - Parameters:
    ///   - contract: define the relationship
    ///   - object:  the related object
    func addRelation(_ relationship:Relationship,to object:Relational)


    /// The owner renounces to its property
    ///
    /// - Parameter object: the object
    func removeOwnerShip(of object:Relational)


    /// Renounces to free relationship
    ///
    /// - Parameter object: the object
    func removeFreeRelationShip(to object:Relational)


    /// Remove a relation to another object
    ///
    /// - Parameters:
    ///   - relationship: define the relationship
    ///   - object:  object: the owned object
    func removeRelation(_ relationship:Relationship,to object:Relational)

    ///  Returns the contracted relations
    ///
    /// - Parameters:
    ///   - relationship:  the nature of the contract
    /// - Returns: the UIDS
    func getContractedRelations(_ relationship:Relationship)->[UID]

}
