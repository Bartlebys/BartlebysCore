//
//  Model+Aliasable.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// MARK: - Model + Aliasable

extension Model:Aliasable{

    /// Creates a `Codable` entity that encapsulates the serialized UID
    ///
    /// - Returns: the serialized entity
    open func alias()->Alias{
        return Alias(UID:self.UID)
    }

}
