//
//  BCollection.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 02/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation
#if !USE_EMBEDDED_MODULES
    import BartlebysCore
#endif
public class ManagedCollectionOf<T>:CollectionOf<T>, ManagedCollection  where T : Managed {

    public override subscript(index: Int) -> T {
        get {
            return self._storage[index]
        }
        set(newValue) {
            self._storage[index] = newValue
            self.hasChanged = true
            self.reference(newValue)
            // Staging @todo is it the good place?
            do{
                try self.stage(newValue)
            }catch{
                Logger.log("\(error)", category: .critical)
            }
        }
    }

    // MARK: - OpaqueCollection


    // Staged identifiers (used to determine what should be committed on the next loop)
    fileprivate var _staged=[String]()

    // Store the identifiers to be deleted on the next loop
    fileprivate var _deleted=[String]()

    /// Overrides the default Erasable Collection method
    ///
    /// - Parameter item: the item to remove
    /// - Throws: erasing error on type miss match
    override public func remove<C:Codable & Collectible>(_ item: C)throws->() {
        try self.remove(item, commit: true)
    }

    /// A remove function with type erasure to enable to perform dynamic cascading removal.
    //  used in ManagedModel+Erasure
    ///
    /// - Parameters:
    ///   - item: the item to erase
    ///   - commit: should we commit the erasure?
    public func remove<C:Codable & Collectible>(_ item: C , commit:Bool)throws->(){
        guard let castedItem = item as? T else{
            throw ErasingError.typeMissMatch
        }
        guard item is Tolerent else{
            throw CollectionOfError.collectedTypeMustBeTolerent
        }
        if let idx = self._storage.index(where:{ return $0.id == castedItem.id }){
            self._storage.remove(at: idx)
        }
        // @todo commit
    }


    /// A remove function with type erasure to enable to perform dynamic cascading removal.
    //  used in ManagedModel+Erasure
    ///
    /// - Parameters:
    ///   - item: the item to erase
    ///   - commit: should we commit the erasure?
    public func stage<C:Codable & Collectible>(_ instance:C)throws -> (){
        guard let castedInstance = instance as? T else{
            throw CollectionOfError.typeMissMatch
        }
        guard instance is Tolerent else{
            throw CollectionOfError.collectedTypeMustBeTolerent
        }
        guard self._staged.contains(castedInstance.UID) else{
            return
        }
        self._staged.append(castedInstance.UID)
        self.hasChanged = true
    }


    /// Commit all the staged changes and planned deletions.
    public func commitChanges(){

        guard let dataPoint = self.dataPoint else{
            return
        }

        if self._staged.count>0{

            var changedInstances=[T]()
            for itemUID in self._staged{
                do{
                    let o:T = try dataPoint.registredObjectByUID(itemUID)
                    changedInstances.append(o)
                }catch{
                    Logger.log("\(error)", category: .critical)
                }
            }
            if changedInstances.count > 0 {
                // Upsert<T>.commit(changedLocalizedData,in:self.dataPoint)
            }
            self._staged.removeAll()
        }

        if self._deleted.count > 0 {
            var toBeDeletedInstances=[T]()
            for itemUID in self._deleted{
                do{
                    let o:T = try dataPoint.registredObjectByUID(itemUID)
                    toBeDeletedInstances.append(o)
                }catch{
                    Logger.log("\(error)", category: .critical)
                }
            }
            if toBeDeletedInstances.count > 0 {
                //Delete<T>.commit(toBeDeletedLocalizedData, from: self.dataPoint)
                self.dataPoint?.unRegister(toBeDeletedInstances)
            }
            self._deleted.removeAll()
        }
    }
}
