//
//  AliasResolver.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public enum AliasResolverError:Error{
    case undefinedContainer
    case typeMissMatch
    case notFound
}


// Addd the ability to resolve Aliases
public protocol AliasResolver{

    /// Resolves the alias
    /// May throw AliasResolverError
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    func instance<T : Codable >(from alias:Alias) throws -> T

    /// Resolves the aliases
    /// May throw AliasResolverError
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    func instances<T : Codable >(from aliases:[Alias]) throws -> [T]

}
