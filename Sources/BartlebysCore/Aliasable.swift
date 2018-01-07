//
//  Aliasable.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public protocol Aliasable:Identifiable{

    /// Creates a `Codable` type erased alias that encapsulates the serialized Identifiable UID
    ///
    /// - Returns: the Aliased entity
    func alias()->Alias


    /// Create a `Codable` typed alias that encapsulttes the serialized Identifiable UID
    ///
    /// - Returns:  the Aliased entity
    func aliasOf<T>()->AliasOf<T>

}
