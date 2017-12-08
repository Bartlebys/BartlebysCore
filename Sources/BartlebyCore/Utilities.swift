//
//  Utilities.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 17/11/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public struct Utilities {
    
    /// Creates an Universal Unique Identifier
    ///
    /// - Returns: returns the identifier
    public static func createUID() -> String {
        let uid = UUID.init().uuidString
        let utf8 = uid.data(using: .utf8)!
        return utf8.base64EncodedString()
    }
    
}
