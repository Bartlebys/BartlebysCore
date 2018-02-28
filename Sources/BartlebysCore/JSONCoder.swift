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

    static public var patcher = JSONPatcher()

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
            let patchedData = try JSONCoder.patcher.patchObject(type, from: data)
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
           let patchedData = try JSONCoder.patcher.patchArrayOf(T.self, from: data)
            return try JSON.decoder.decode([T].self, from: patchedData)
        }
    }


    public init(){
    }

}
