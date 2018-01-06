//
//  KeyedData+Tolerent.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

extension KeyedData : Tolerent {

    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        // There is no reason to have a malformed KeyedData
        // But we want to be able to insure the Tolerent persistency of KeyedData
    }

}
