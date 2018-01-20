//
//  JSONCoder.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 10/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

// Tolerent Json encoder and decoder
open class JSONCoder:ConcreteCoder{


    // MARK : - ConcreteCoder
    /// Encodes the given top-level value and returns its representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    public func encode<T : Encodable>(_ value: T) throws -> Data{
        return try JSON.encoder.encode(value)
    }

    // MARK : - ConcreteDecoder


    /// Decodes a top-level value of the given type from the given  representation.
    /// If the decoding fails it tries to patch the data
    ///
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid .
    /// - throws: An error if any value throws an error during decoding.
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable{
        do{
            // Try a to decode normally
            return try JSON.decoder.decode(T.self, from: data)
        }catch{
            guard let TolerentType = T.self as? Tolerent.Type else{
                throw TolerentError.isNotTolerent(decodingError: error)
            }
            // Patch the object
            let patchedData = try self._patchObject(data: data, resultType: TolerentType)
            return try JSON.decoder.decode(T.self, from: patchedData)

        }
    }

    /// Decodes a top-level value of the given type from the given  representation.
    ///
    /// - parameter data: The data to decode.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid .
    /// - throws: An error if any value throws an error during decoding.
    public func decodeArrayOf<T>(_ type: T.Type, from data: Data) throws -> [T] where T : Decodable{
        do{
            // Try a to decode normally
            return try JSON.decoder.decode([T].self, from: data)
        }catch{
            guard let TolerentType = T.self as? Tolerent.Type else{
                throw TolerentError.isNotTolerent(decodingError: error)
            }
            let patchedData = try self._patchCollection(data: data, resultType:TolerentType)
            return try JSON.decoder.decode([T].self, from: patchedData)
        }
    }

    // MARK: -  Tolerent Patches

    /// Patches JSON data according to the attended Type
    ///
    /// - Parameters:
    ///   - data: the data
    ///   - resultType: the result type
    /// - Returns: the patched data
    fileprivate func _patchObject(data: Data, resultType: Tolerent.Type) throws -> Data {
        return try syncOnMainAndReturn(execute: { () -> Data in
            if var jsonDictionary = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments, JSONSerialization.ReadingOptions.mutableLeaves, JSONSerialization.ReadingOptions.mutableContainers]) as? Dictionary<String, Any> {
                resultType.patchDictionary(&jsonDictionary)
                return try JSONSerialization.data(withJSONObject:jsonDictionary, options:[])
            }else{
                throw SessionError.deserializationFailed
            }
        })
    }

    /// Patches collection of JSON data according to the attended Type
    ///
    /// - Parameters:
    ///   - data: the data
    ///   - resultType: the result type
    /// - Returns: the patched data
    fileprivate func _patchCollection(data: Data, resultType: Tolerent.Type) throws -> Data {
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
                throw SessionError.deserializationFailed
            }
        })
    }

    public init(){
    }

}
