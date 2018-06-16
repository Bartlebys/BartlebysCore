//
//  Utilities.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 17/11/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public struct Utilities {
    
    /// Creates an Universal Unique Identifier
    ///
    /// - Returns: returns the identifier
    public static func createUID() -> UID {
        
        if BASE64_ENCODED_UIDS {
            let uid = UUID.init().uuidString
            let encoded = uid.data(using: Default.STRING_ENCODING)!
            return encoded.base64EncodedString()
        } else {
            let uid = UUID.init().uuidString.replacingOccurrences(of: "-", with: "")
            return uid
        }

    }
    
}
