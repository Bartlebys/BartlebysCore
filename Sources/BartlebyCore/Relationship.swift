//
//  Relationship.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 28/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public enum Relationship:String{

    /// Serialized into the Object
    case free = "free"
    case ownedBy = "ownedBy"

    /// "owns" is Computed at runtime during registration to determine the the Subject
    /// Ownership is computed asynchronously for better resilience to distributed pressure
    /// Check ManagedCollection.propagate()
    case owns = "owns"

}
