//
//  Model+Aliasable.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// MARK: - Model + Aliasable

extension Model:Aliasable{

    /// Creates a `Codable` type erased alias that encapsulates the serialized Identifiable UID
    ///
    /// - Returns: the Aliased entity

    public func alias()->Alias{
        return Alias(UID:self.UID)
    }


    /// Create a `Codable` typed alias that encapsulttes the serialized Identifiable UID
    ///
    /// - Returns:  the Aliased entity
    public func aliasOf<T>()->AliasOf<T>{
        return AliasOf(UID:self.UID)
    }
    
}
