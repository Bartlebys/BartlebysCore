//
//  Metrics+Tolerent.swift
//  BartlebysCoreTests
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

extension Metrics : Tolerent {
    
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        // Metrics is used by unit tests. There is no reason to have a malformed metrics
    }
    
}
