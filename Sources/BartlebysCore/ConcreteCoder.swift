//
//  ConcreteCoder.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 10/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol ConcreteCoder:ConcreteEncoder, ConcreteDecoder{
}

public protocol ConcreteEncoder{

    /// Encodes the given top-level value and returns its representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded  data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    func encode<T : Encodable >(_ value: T) throws -> Data

}

public protocol ConcreteDecoder{

    /// Decodes a top-level value of the given type from the given  representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid .
    /// - throws: An error if any value throws an error during decoding.
    func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T


    /// Decodes a top-level value of the given type from the given  representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid .
    /// - throws: An error if any value throws an error during decoding.
    func decodeArrayOf<T : Decodable>(_ type: T.Type, from data: Data) throws -> [T]

}
