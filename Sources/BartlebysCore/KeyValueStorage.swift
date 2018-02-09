//
//  KeyValueStorage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public protocol KeyValueStorage{

    // MARK: - Codable

    /// Save the state of a codable into the dataPoint keyedData
    /// E.g : save indexes, datapoint related preferences (not app wide)
    ///
    /// - Parameters:
    ///   - value: the value
    ///   - key: the identification key (must be unique)
    func storeInKVS<T:Codable>(_ value:T,identifiedBy key:String)throws->()


    /// Recover the saved instance (this implementation is not Tolerent)
    ///
    /// - Parameter byKey: the identification key (must be unique)
    /// - Returns: the value
    /// - Throws: KeyValueStorageError.keyNotFound if the key is not set, and JSON coder error on decoding issue
    func getFromKVS<T:Codable>(key:String)throws ->T


    /// Returns if the KVS contains a value for this key.
    ///
    /// - Parameter key: the key
    /// - Returns: true if the key exists
    func hasValueFor(key:String) -> Bool


}
