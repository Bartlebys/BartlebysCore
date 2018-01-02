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
        let uid = UUID.init().uuidString
        let utf8 = uid.data(using: .utf8)!
        return utf8.base64EncodedString()
    }
    
}
