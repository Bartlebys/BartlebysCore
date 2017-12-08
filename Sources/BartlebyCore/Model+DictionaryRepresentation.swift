//
//  ManagedModel+DictionaryRepresentation.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 05/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

extension Model {
    
    func toDictionaryRepresentation() -> Dictionary<String, Any> {
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
