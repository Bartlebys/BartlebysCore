//
//  DataPoint+KeyValueStorage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public enum KeyValueStorageError:Error{
    case keyNotFound(key:String)
    case noContainerRootValueNotFound
}


extension DataPoint:KeyValueStorage{


    // MARK: - Codable

    /// Save the state of a codable into the dataPoint keyedData
    /// E.g : save indexes, datapoint related preferences (not app wide)
    ///
    /// - Parameters:
    ///   - value: the value
    ///   - key: the identification key (must be unique)
    public func storeInKVS<T:Codable>(_ value:T,identifiedBy key:String)throws->(){
        let data:Data
        // JSON need a container
        // single Int is Codable but is not a valid json
        let collectionsTypes = Set(arrayLiteral: "Set", "Array", "Dictionary")
        let typeString = String(describing: type(of: value))
        if collectionsTypes.contains(typeString){
            data = try JSON.encoder.encode(value)
        }else{
            data = try JSON.encoder.encode([DataPoint.noContainerRootKey:value])
        }
        let keyedData = KeyedData()
        keyedData.key = key
        keyedData.data = data
        if let index = self.keyedDataCollection.index(where:{$0.key == key}){
            self.keyedDataCollection[index] = keyedData
        }else{
            self.keyedDataCollection.append(keyedData)
        }
    }


    /// Recover the saved instance (this implementation is not Tolerent)
    ///
    /// - Parameter byKey: the identification key (must be unique)
    /// - Returns: the value
    /// - Throws: KeyValueStorageError.keyNotFound if the key is not set, and JSON coder error on decoding issue
    public func getFromKVS<T:Codable>(key:String) throws -> T {
        guard let keyedData = self.keyedDataCollection.first(where:{$0.key == key }) else {
            throw KeyValueStorageError.keyNotFound(key: key)
        }
        let data = keyedData.data
        
        let collectionsTypes = Set(arrayLiteral: "Set", "Array", "Dictionary")
        let typeString = String(describing: type(of: T.self))
        if collectionsTypes.contains(typeString) {
            let instance = try JSON.decoder.decode(T.self, from: data)
            if let model = instance as? Model {
                self.register(model)
            }
            return instance
        } else {
            let container:[String:T] = try JSON.decoder.decode([String:T].self, from: data)
            if let instance = container[DataPoint.noContainerRootKey] {
                if let model = instance as? Model {
                    self.register(model)
                }
                return instance
            } else {
                throw KeyValueStorageError.noContainerRootValueNotFound
            }
        }
        
    }

    /// Recover the saved instance (For Tolerent instances)
    ///
    /// - Parameter byKey: the identification key (must be unique)
    /// - Returns: the value
    /// - Throws: KeyValueStorageError.keyNotFound if the key is not set, and JSON coder error on decoding issue
    public func getFromKVS<T:Codable & Tolerent >(key:String)throws ->T{
        guard let keyedData = self.keyedDataCollection.first(where:{$0.key == key }) else {
            throw KeyValueStorageError.keyNotFound(key: key)
        }
        let data = keyedData.data
        let instance = try self.storage.coder.decode(T.self, from: data)
        return instance
    }



    /// Returns if the KVS contains a value for this key.
    ///
    /// - Parameter key: the key
    /// - Returns: true if the key exists
    public func hasValueFor(key:String) -> Bool{
        return self.keyedDataCollection.first(where:{$0.key == key }) != nil
    }



}
