//
//  TolerentDeserialization.swift
//  LPSynciOS
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public protocol TolerentDeserialization {

    /// You should implement this protocol on any Codable object
    /// If you want to be able to fix conformity or versioning issues on deserialization.
    ///
    /// - Parameter dictionary: the dictionary
    static func patchDictionary(_ dictionary: inout Dictionary<String, Any>)

}
