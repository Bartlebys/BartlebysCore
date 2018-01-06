//
//  DataPoint+KeyValueStorage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public enum KeyValueStorageError:Error{
    case keyNotFound
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
        let data = try JSON.encoder.encode(value)
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
    public func getFromKVS<T:Codable>(key:String)throws ->T{
        guard let keyedData = self.keyedDataCollection.first(where:{$0.key == key }) else {
            throw KeyValueStorageError.keyNotFound
        }
        let data = keyedData.data
        let instance = try JSON.decoder.decode(T.self, from: data)
        return instance
    }


    // MARK: - Codable & Tolerent


    /// Recover the saved instance (Tolerent)
    ///
    /// - Parameter byKey: the identification key (must be unique)
    /// - Returns: the value
    /// - Throws: KeyValueStorageError.keyNotFound if the key is not set, and JSON coder error on decoding issue
    public func getFromKVS<T:Codable & Tolerent>(key:String)throws ->T{
        guard let keyedData = self.keyedDataCollection.first(where:{$0.key == key }) else {
            throw KeyValueStorageError.keyNotFound
        }
        let data = keyedData.data
        let instance = try self.coder.decode(T.self, from: data)
        return instance
    }


    // MARK: - Strings


    /// Save a string into the dataPoint keyedData
    /// E.g : save indexes, datapoint related preferences (not app wide)
    ///
    /// - Parameters:
    ///   - value: the string
    ///   - key: the identification key (must be unique)
    public func storeInKVS(_ value:String,identifiedBy key:String)throws->(){
        let data = try JSON.base64Encoder.encode([value])
        let keyedData = KeyedData()
        keyedData.key = key
        keyedData.data = data
        if let index = self.keyedDataCollection.index(where:{$0.key == key}){
            self.keyedDataCollection[index] = keyedData
        }else{
            self.keyedDataCollection.append(keyedData)
        }
    }


    /// Recover the saved string
    ///
    /// - Parameter byKey: the identification key (must be unique)
    /// - Returns: the string
    /// - Throws: KeyValueStorageError.keyNotFound if the key is not set, JSON coder error on decoding issue
    public func getFromKVS(key:String)throws ->String{
        guard let keyedData = self.keyedDataCollection.first(where:{$0.key == key }) else {
            throw KeyValueStorageError.keyNotFound
        }
        let data = keyedData.data
        let instance = try JSON.base64Decoder.decode([String].self, from: data)
         return instance[0]

    }


}
