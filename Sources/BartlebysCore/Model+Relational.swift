//
//  ManagedModel+Relational.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//
//

import Foundation


// MARK: - Without reciprocity

// "free"
// In case of deletion of one of the related terms the other is preserved
// (there is not necessarly reciprocity of the relation)
// E.G: tags can freely associated
// N -> N


// MARK: - With reciprocity

// "owns"
// "ownedBy": reciprocity of "owns"
// In case of deletion of the owner the owned is automatically deleted.
// If all the owners are deleted their "ownees" are deleted.
// N -> N


extension Model: Relational{
 
    // MARK: - Relationships Declaration

    /// An Object enters in a free relation Ship with another
    ///
    /// - Parameters:
    ///   - object:  object: the owned object
    public func declaresFreeRelationShip(to object: Relational){
        self.addRelation(.free,to: object)
    }


    /// The owner declares its property
    /// Both relation are setup owns, and owned
    ///
    /// - Parameters:
    ///   - object:  object: the owned object
    public func declaresOwnership(of object: Relational){
        self.addRelation(.owns,to: object)
        object.addRelation(.ownedBy,to: self)
    }




    /// Add a relation to another object
    /// - Parameters:
    ///   - contract: define the relationship
    ///   - object:  the related object
    public func addRelation(_ relationship: Relationship,to object: Relational){
        switch relationship {
        case Relationship.free:
            if !self.freeRelations.contains(object.uid){
                self.freeRelations.append(object.uid)
            }
            break
        case Relationship.owns:
            if !self.owns.contains(object.uid){
                self.owns.append(object.uid)
            }
            break
        case Relationship.ownedBy:
            if !self.ownedBy.contains(object.uid){
                self.ownedBy.append(object.uid)
            }
            break
        }
    }



    /// The owner renounces to its property
    ///
    /// - Parameter object: the object
    public func removeOwnerShip(of object: Relational){
        self.removeRelation(Relationship.owns, to: object)
    }

    /// Renounces to free relationship
    ///
    /// - Parameter object: the object
    public func removeFreeRelationShip(to object:Relational){
        self.removeRelation(Relationship.free, to: object)
    }



    /// Remove a relation to another object
    ///
    /// - Parameter object: the object
    public func removeRelation(_ relationship: Relationship,to object: Relational){
        switch relationship {
        case Relationship.free:
            if let idx = self.freeRelations.index(of:object.uid){
                self.freeRelations.remove(at: idx)
            }
            break
        case Relationship.owns:
            if let idx = self.owns.index(of:object.uid){
                self.owns.remove(at: idx)
                object.removeRelation(Relationship.ownedBy, to: self)
            }
            break
        case Relationship.ownedBy:
            if let idx = self.ownedBy.index(of:object.uid){
                self.ownedBy.remove(at: idx)
            }
            break
        }
    }


    ///  Returns the contracted relations
    ///
    /// - Parameters:
    ///   - relationship:  the nature of the contract
    /// - Returns: the relations
    public func getContractedRelations(_ relationship: Relationship)->[UID]{
        switch relationship {
        case Relationship.free:
            return self.freeRelations
        case Relationship.owns:
            return self.owns
        case Relationship.ownedBy:
            return self.ownedBy
        }
    }
    
}
