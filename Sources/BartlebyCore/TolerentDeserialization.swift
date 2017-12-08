//
//  TolerentDeserialization.swift
//  LPSynciOS
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public protocol TolerentDeserialization {

    static func patchDictionary(_ dictionary: inout Dictionary<String, Any>)

}
