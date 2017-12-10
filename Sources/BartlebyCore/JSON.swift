//
//  JSON.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

// A bunch of preconfigured encoder and decoders
open class JSON{

    open static var encoder:JSONEncoder{
        get{
            let encoder = JSONEncoder()
            encoder.nonConformingFloatEncodingStrategy = .throw
            if #available(iOS 10.0, OSX 10.12, *){
                encoder.dateEncodingStrategy = .iso8601
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                encoder.dateEncodingStrategy = .formatted(formatter)
            }
            return encoder
        }
    }

    open static var prettyEncoder:JSONEncoder{
        let encoder = JSON.encoder
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }


    open static var base64Encoder:JSONEncoder{
        let encoder = JSON.encoder
        encoder.dataEncodingStrategy = .base64
        return encoder
    }

    open static var decoder:JSONDecoder{
        get{
            let decoder = JSONDecoder()
            decoder.nonConformingFloatDecodingStrategy = .throw
            if #available(iOS 10.0, OSX 10.12, *) {
                decoder.dateDecodingStrategy = .iso8601
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                decoder.dateDecodingStrategy = .formatted(formatter)
            }
            return decoder
        }
    }


    open static var base64Decoder:JSONDecoder{
        let decoder = JSON.decoder
        decoder.dataDecodingStrategy = .base64
        return decoder
    }

}

// MARK: - ConcreteJSONCoder

open class ConcreteJSONCoder:ConcreteCoder{

    // MARK : - ConcreteCoder
    /// Encodes the given top-level value and returns its representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> Data{
        return try JSON.encoder.encode(value)
    }

    // MARK : - ConcreteDecoder

    /// Decodes a top-level value of the given type from the given  representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid .
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T{
        return try JSON.decoder.decode(type, from: data)
    }

    public init(){
    }

}

// MARK: - ConcretePrettyJSONCoder

open class ConcretePrettyJSONCoder:ConcreteJSONCoder{

    // MARK : - ConcreteCoder
    /// Encodes the given top-level value and returns its representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    override open func encode<T : Encodable>(_ value: T) throws -> Data{
        return try JSON.prettyEncoder.encode(value)
    }
}

