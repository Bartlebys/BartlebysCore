//
//  Patcher.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 26/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public enum PatcherError : Error {
    case encodingFailure
}

open class Patcher{


    // MARK: - Tolerent Patches

    /// Patches the data of a single object
    ///
    /// - Parameters:
    ///   - type: for a given type
    ///   - data: the daa
    /// - Returns: the patched data
    /// - Throws: TolerentError & PatcherError
    open func patchObject<T>(_ type: T.Type, from data: Data) throws -> Data{

        guard let TolerentType = T.self as? Tolerent.Type else{
            throw TolerentError.isNotTolerent
        }
        // Patch the object
        let patchedData = try self.applyPatchOnObject(data: data, resultType: TolerentType)
        return patchedData
    }

    /// Patches the data of an array of object
    ///
    /// - Parameters:
    ///   - type: for a given type
    ///   - data: the daa
    /// - Returns: the patched data
    /// - Throws: TolerentError & PatcherError
    open func patchArrayOf<T>(_ type: T.Type, from data: Data) throws -> Data where T : Decodable{
        guard let TolerentType = T.self as? Tolerent.Type else{
            throw TolerentError.isNotTolerent
        }
        let patchedData = try self.applyPatchOnArrayOfObjects(data: data, resultType:TolerentType)
        return patchedData
    }


    /// Patches JSON data according to the attended Type
    ///
    /// - Parameters:
    ///   - data: the data
    ///   - resultType: the result type
    /// - Returns: the patched data
    public final func applyPatchOnObject(data: Data, resultType: Tolerent.Type) throws -> Data {
        return try syncOnMainAndReturn(execute: { () -> Data in
            if var jsonDictionary = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments, JSONSerialization.ReadingOptions.mutableLeaves, JSONSerialization.ReadingOptions.mutableContainers]) as? Dictionary<String, Any> {
                resultType.patchDictionary(&jsonDictionary)
                return try JSONSerialization.data(withJSONObject:jsonDictionary, options:[])
            }else{
                throw PatcherError.encodingFailure
            }
        })
    }

    /// Patches collection of JSON data according to the attended Type
    ///
    /// - Parameters:
    ///   - data: the data
    ///   - resultType: the result type
    /// - Returns: the patched data
     public final func applyPatchOnArrayOfObjects(data: Data, resultType: Tolerent.Type) throws -> Data {
        return try syncOnMainAndReturn(execute: { () -> Data in
            if var jsonObject = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments, JSONSerialization.ReadingOptions.mutableLeaves, JSONSerialization.ReadingOptions.mutableContainers]) as? Array<Dictionary<String, Any>> {
                var index = 0
                for var jsonElement in jsonObject {
                    resultType.patchDictionary(&jsonElement)
                    jsonObject[index] = jsonElement
                    index += 1
                }
                return try JSONSerialization.data(withJSONObject: jsonObject, options:[])
            }else{
                throw PatcherError.encodingFailure
            }
        })
    }

    
}
