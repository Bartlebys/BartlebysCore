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
     public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Tolerent, T : Decodable{
        do{
            // Try a to decode normally
            return try JSON.decoder.decode(T.self, from: data)
        }catch{
            // Patch the object
            let patchedData = try self._patchObject(data: data, resultType: T.self)
            return try JSON.decoder.decode(T.self, from: patchedData)
        }
    }
    
    /// Decodes a top-level value of the given type from the given  representation.
    ///
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid .
    /// - throws: An error if any value throws an error during decoding.
    public func decodeArrayOf<T>(_ type: T.Type, from data: Data) throws -> [T] where T : Tolerent, T : Decodable{
        do{
            // Try a to decode normally
            return try JSON.decoder.decode([T].self, from: data)
        }catch{
            let patchedData = try self._patchCollection(data: data, resultType: T.self)
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
        return try Object.syncOnMainAndReturn(execute: { () -> Data in
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
        return try Object.syncOnMainAndReturn(execute: { () -> Data in
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


public extension Data{
    
    /// Determinate if a data is possibly a JSON collection
    ///
    /// - Parameter data: the data
    /// - Returns: true if the JSON is posssibly a collection (there is no semantic validation of the JSON)
    public var mayContainMultipleJSONObjects:Bool{
        // this implementation is sub-optimal.
        if let string = String(data: self, encoding: String.Encoding.utf8){
            // We have the string let's log it
            Logger.log(string,category: .temporary)
            for c in string{
                if c == "["{
                    return true
                }
                if c == "{"{
                    break
                }
            }
        }
        return false
    }
    
}
