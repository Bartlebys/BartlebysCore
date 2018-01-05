//
//  ManagedModel+Erasure.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation


public enum ErasingError:Error {
    case dataPointUndefined
    case typeMissMatch
    case notTolerent
    case referentDocumentUndefined // @todo to be removed
}


extension Model{


   // @TODO!
   // Write func remove<C: Codable & Collectible>(_ item: C)throws->()
   // Call this method from  func remove<CollectibleType:Codable & Collectible>(_ item: CollectibleType , commit:Bool)throws->()


    /// Erases globally the instance and its dependent relations.
    /// Throws  ErasingError.dataPointUndefined
    /// You may invoke sanitizing routines on document.willErase (e.g:  purge files  Node, Block, ...)
    /// - Parameters:
    ///   - commit: set to true by default (we set to false only  not to commit triggered Deletion)
    ///   - eraserUID: the eraser UID (used by recursive calls to determinate if co-owned children must be erased)
    /// - Returns: N/A
    public func erase(commit:Bool=true,eraserUID:String="NO_UID")throws->(){
        
        guard let dataPoint=self.dataPoint else{
            throw ErasingError.dataPointUndefined
        }
    

        // #TODO write specific Unit test for real cases validation (in BSFS and YD)
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
        dataPoint.willErase(self)
        if let managedOpaqueCollection = self.parentCollection{
            try managedOpaqueCollection.remove(self,commit:true)
        }else{
            try self.erasableCollection?.remove(self)
        }


        var erasableUIDS:[String]=[self.UID]

        // Erase recursively
        func __stageForErasure(_ objectUID:String,eraserUID:String="NO_UID")throws->(){
            if !erasableUIDS.contains(objectUID){
                erasableUIDS.append(objectUID)
                let target:Model = try dataPoint.registredObjectByUID(objectUID)
                try target.erase(commit: commit)
            }
        }

        try self.owns.forEach({ (objectUID) in
            try __stageForErasure(objectUID,eraserUID: self.UID)
        })


        self.ownedBy.forEach({ (ownerObjectUID) in
            // Remove the homologous relation
            if let owner:Model = try? dataPoint.registredObjectByUID(ownerObjectUID){
                owner.removeRelation(Relationship.owns, to:self)
            }
        })

        // What should we do for free relations?
        // That's FreeDom! There is nothing to do with self.free

        // Let's unRegister
        dataPoint.unRegister(self)


    }

}
