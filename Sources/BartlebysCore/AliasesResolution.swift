//
//  AliasResolver.swift
//  BartlebysCore
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
public protocol AliasesResolution{

    /// Resolves the alias
    /// May throw AliasResolverError
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    func instance<T : Codable & Collectable >(from alias:Aliased) throws -> T


    /// Resolves the aliases
    /// Verify that all the instance are available
    /// May throw AliasResolverError
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    func instances<T : Codable & Collectable >(from aliases:[Aliased]) throws -> [T]


    // MARK: - Optionals
    

    /// Resolves the optional instance alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    func optionalInstance<T : Codable & Collectable>(from alias:Aliased?) -> T?


    /// Resolves the aliases
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    func optionalInstances<T : Codable & Collectable>(from aliases:[Aliased]) -> [T]


}
