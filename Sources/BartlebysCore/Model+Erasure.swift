//
//  Model+Erasure.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation


public enum ErasingError: Error {
    case undefinedContainer
    case typeMissMatch
}


/// This extension implement relational erasure
/// It also expose a Commit property to enable to implement ManagedCollection
/// A non fully Managed model is not concerned by those details
extension Model{


    /// Erases globally the instance and its dependent relations.
    /// Throws  ErasingError.dataPointUndefined
    /// You may invoke sanitizing routines on dataPoint.willErase (e.g:  purge files  Node, Block, ...)
    ///
    /// - Parameters:
    ///   - commit: set to true by default (used byFully Managed Framework e.g: BarlebyKit commit is set to false not to commit triggered Deletion)
    ///   - eraserUID: the eraser UID (used by recursive calls to determinate if co-owned children must be erased)
    /// - Returns: N/A
    public func erase(commit: Bool = true,eraserUID: String = "NO_UID")throws->(){
        
        guard let dataPoint=self.dataPoint else{
            throw ErasingError.undefinedContainer
        }

        // Co-ownership (used by recursive calls)
        // Preserves ownees with multiple Owners
        if self.ownedBy.count > 1 && eraserUID != "NO_UID"{
            if let idx = self.ownedBy.index(of: eraserUID){
                // Remove the homologous relation
                if let owner:Model = try? dataPoint.registredObjectByUID(eraserUID){
                    owner.removeRelation(Relationship.owns, to:self)
                    return
                }
            }
        }

        // Call the overridable cleaning method
        // This may ne the time for dependent file cleaning.
        dataPoint.willErase(self)
        
        if let managedOpaqueCollection = self.managedCollection{
            try managedOpaqueCollection.removeItem(self,commit:commit)
        }else{
            try self.indistinctCollection?.removeItem(self)
        }

        var erasableUIDS:[String]=[self.uid]

        // Erase recursively
        func __stageForErasure(_ objectUID:String,eraserUID:String="NO_UID")throws->(){
            if !erasableUIDS.contains(objectUID){
                erasableUIDS.append(objectUID)
                let target:Model = try dataPoint.registredObjectByUID(objectUID)
                try target.erase(commit: commit,eraserUID: eraserUID)
            }
        }

        try self.owns.forEach({ (objectUID) in
            try __stageForErasure(objectUID,eraserUID: self.uid)
        })


        self.ownedBy.forEach({ (ownerObjectUID) in
            // Remove the homologous relation
            if let owner:Model = try? dataPoint.registredObjectByUID(ownerObjectUID){
                owner.removeRelation(Relationship.owns, to:self)
            }
        })

        // What should we do for free relations?
        // - There is nothing to do with self.free !

        // Let's unRegister
        dataPoint.unRegister(self)

    }

}
