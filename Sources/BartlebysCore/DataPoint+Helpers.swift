//
//  DataPoint+Helpers.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 13/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


extension DataPoint{


    /// Removes the registred instances from the registry
    ///
    /// - Parameter instance: the instance
    public func unRegister<T:  Codable & Collectable >(_ instances: [T]) {
        for instance in instances{
            self.unRegister(instance)
        }
    }

    // MARK: - Model level

    /// Returns a Model by its UID
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectable>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredModelByUID(_ UID: UID)-> Model? {
        return try? self.registredObjectByUID(UID)
    }

    /// Returns a collection of Model by UIDs
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectable>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredModelByUIDs(_ UIDs: [UID])-> [Model]? {
        return try? self.registredObjectsByUIDs(UIDs)
    }


    /// Removes the registered item by its UID
    ///
    /// - Parameter uid: the UID
    /// - Returns: the item if found.
    public func removeRegistredModelByUID(_ uid:UID)->Model?{
        if let instance = self.registredModelByUID(uid){
            let collectionName = instance.d_collectionName
            if let collection = self.collectionNamed(collectionName){
                do{
                    let _ = try collection.removeItem(instance)
                }catch{
                    Logger.log(error, category: .critical)
                }
            }
            return instance
        }
        return nil
    }

    
}
