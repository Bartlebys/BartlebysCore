//
//  Alias.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// MARK: - Aliasable

public protocol Aliasable{

    /// Creates a `Codable` alias that encapsulates the serialized UID
    ///
    /// - Returns: the serialized entity
    func alias()->Alias
}

// MARK: - AliasResolver

// Addd the ability to resolve Aliases
public protocol AliasResolver{

    /// Resolve the alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    func instance<T : Codable >(from alias:Alias)->T?

}

/// The alias struct
public struct Alias:Codable{
    public let UID:String
}




