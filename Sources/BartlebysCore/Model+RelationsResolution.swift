//
//  ManagedModel+RelationsResolution.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//
//

import Foundation

extension Model:RelationsResolution{

    /// Resolve the Related Objects
    ///
    /// - Parameters:
    ///   - relationship: the searched relationship
    /// - Returns: return the related Objects
    public func relations<T:Relational>(_ relationship:Relationship)->[T]{
        var related=[T]()
        guard let dataPoint = self.dataPoint else{
            return related
        }
        for object in self.getContractedRelations(relationship){

            if let candidate = try? dataPoint.registredObjectByUID(object) as Model{
                if let casted = candidate as? T{
                    related.append(casted)
                }
            }
        }
        return related
    }


    /// Resolve the filtered Related Objects
    ///
    /// - Parameters:
    ///   - relationship: the searched relationship
    ///   - included: the filtering closure
    /// - Returns: return the related Objects
    public func filteredRelations<T:Relational>(_ relationship:Relationship,included:(T)->(Bool))->[T]{
        var related=[T]()
        guard let dataPoint = self.dataPoint else{
            return related
        }
        for object in self.getContractedRelations(relationship){
            if let candidate = try? dataPoint.registredObjectByUID(object) as Model{
                if let casted = candidate as? T{
                    if  included(casted) == true {
                        related.append(casted)
                    }
                }
            }
        }
        return related
    }


    /// Resolve the filtered Related Objects
    ///
    /// - Parameters:
    ///   - relationship: the searched relationship
    ///   - included: the filtering closure
    /// - Returns: return the related Objects as values and the UID as keys
    public func hashedFilteredRelations<T:Relational>(_ relationship:Relationship,included:(T)->(Bool))->[UID:T]{
        var related=[String:T]()
        guard let dataPoint = self.dataPoint else{
            return related
        }
        for object in self.getContractedRelations(relationship){
            if let candidate = try? dataPoint.registredObjectByUID(object) as Model{
                if let casted = candidate as? T{
                    if  included(casted) == true {
                        related[casted.UID]=casted
                    }
                }
            }
        }
        return related
    }


    /// Resolve the Related Objects
    ///
    /// - Parameters:
    ///   - relationship: the searched relationships
    /// - Returns: return the related Objects
    public func relationsInSet<T:Relational>(_ relationships:Set<Relationship>)->[T]{
        var related=[T]()
        var objectsUID=[String]()
        for relationShip in relationships{
            objectsUID.append(contentsOf:self.getContractedRelations(relationShip))
        }
        guard let dataPoint = self.dataPoint else{
            return related
        }
        for objectUID in objectsUID{
            if let candidate = try? dataPoint.registredObjectByUID(objectUID) as Model{
                if let casted = candidate as? T{
                    related.append(casted)
                }
            }
        }
        return related
    }


    /// Resolve the filtered Related Objects
    ///
    /// - Parameters:
    ///   - relationship: the searched relationships
    ///   - included: the filtering closure
    /// - Returns: return the related Objects
    public func filteredRelationsInSet<T:Relational>(_ relationships:Set<Relationship>,included:(T)->(Bool))->[T]{
        var related=[T]()
        var objectsUID=[String]()
        for relationShip in relationships{
            objectsUID.append(contentsOf:self.getContractedRelations(relationShip))
        }
        guard let dataPoint = self.dataPoint else{
            return related
        }
        for objectUID in objectsUID{
            if let candidate = try? dataPoint.registredObjectByUID(objectUID) as Model{
                if let casted = candidate as? T{
                    if  included(casted) == true {
                        related.append(casted)
                    }
                }
            }
        }
        return related
    }



    /// Resolve the Related Object and returns the first one
    ///
    /// - Parameters:
    ///   - relationship: the searched relationships
    public func firstRelation<T:Relational>(_ relationship:Relationship)->T?{
        // Internal relations.
        let objectsUID=self.getContractedRelations(relationship)
        if objectsUID.count>0{
            guard let dataPoint = self.dataPoint else{
                return nil
            }
            for objectUID in objectsUID{
                if let candidate = try? dataPoint.registredObjectByUID(objectUID) as Model{
                    if let casted = candidate as? T{
                        return casted
                    }
                }
            }
        }
        return nil
    }


    /// Resolve the Related Object and returns the first one
    ///
    /// - Parameters:
    ///   - relationship: the searched relationships
    ///   - included: the filtering closure
    // - Returns: return the related Object
    public func filteredFirstRelation<T:Relational>(_ relationship:Relationship,included:(T)->(Bool))->T?{
        // Internal relations.
        let objectsUID=self.getContractedRelations(relationship)
        if objectsUID.count>0{
            guard let dataPoint = self.dataPoint else{
                return nil
            }
            for objectUID in objectsUID{
                if let candidate = try? dataPoint.registredObjectByUID(objectUID) as Model{
                    if let castedCandidate = candidate as? T {
                        if  included(castedCandidate) == true {
                            return castedCandidate
                        }
                    }
                }
            }
        }
        return nil
    }

}
