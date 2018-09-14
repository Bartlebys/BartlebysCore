//
//  Encodable+DictionaryRepresentation.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 05/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public extension Encodable {

    /// Returns a dictionary representation of the Model
    ///
    /// - Returns: the dictionary
    public func toDictionaryRepresentation() -> Dictionary<String, Any> {
        do {
            let data = try JSON.encoder.encode(self)
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> {
                return dictionary
            }
        } catch {
            Logger.log("dictionary representation has failed: \(error)")
        }
        return Dictionary<String, Any>()
    }
    
}
