//
//  CollectionOf+Tolerent.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 26/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

extension CollectionOf:Tolerent{


    /// Tolerent implementation
    ///
    /// - Parameter dictionary: the collection dictionary.
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        guard let TolerentType = T.self as? Tolerent.Type else{
            return
        }
        // We want to patch the items
        if let dictionaries = dictionary[CollectionOf.CollectionCodingKeys.items.rawValue] as? [Dictionary<String, Any>] {
            var patched: [Dictionary<String, Any>] =  [Dictionary<String, Any>]()
            for var dictionary in dictionaries{
                //var mutableDictionary = dictionary
                TolerentType.patchDictionary(&dictionary)
                patched.append(dictionary)
            }
            dictionary[CollectionOf.CollectionCodingKeys.items.rawValue] = patched
        }
    }

}
