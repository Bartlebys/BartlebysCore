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
public protocol AliasesResolution: Incorporated{

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


extension AliasesResolution{

    /// Resolves the alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func instance<T: Codable & Collectable>(from alias: Aliased) throws -> T{
        guard let dataPoint = self.dataPoint else{
            throw AliasResolverError.undefinedContainer
        }
        // We want to be able to resolve any object not only Models and ManagedModels
        // So we use the opaque layer.
        let instance =  dataPoint.registredModelByUID(alias.uid)
        guard  instance != nil else {
            throw AliasResolverError.notFound
        }
        guard let castedInstance = instance as? T else{
            throw AliasResolverError.typeMissMatch
        }
        return castedInstance
    }



    /// Resolves the aliases
    /// Verify that all the instance are available
    /// May throw AliasResolverError
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    /// - Throws: AliasResolverError
    public func instances<T: Codable  & Collectable  >(from aliases: [Aliased]) throws -> [T] {
        guard let dataPoint = self.dataPoint else{
            throw AliasResolverError.undefinedContainer
        }
        let UIDs = aliases.map { $0.uid }
        let instances:[T] = try dataPoint.registredObjectsByUIDs(UIDs)
        return instances
    }

    // MARK: - Optionals

    /// Resolves the optional instances alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func optionalInstance<T : Codable  & Collectable >(from alias: Aliased) -> T?{
        guard let dataPoint = self.dataPoint else{
            return nil
        }

        return  dataPoint.registredModelByUID(alias.uid) as? T
    }

    /// Resolves the optional instance alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func optionalInstance<T: Codable & Collectable>(from alias: Aliased?) -> T?{
        guard let alias = alias,let dataPoint = self.dataPoint else{
            return nil
        }
        return dataPoint.registredModelByUID(alias.uid) as? T
    }


    /// Resolves the optionals aliases
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    public func optionalInstances<T: Codable>(from aliases: [Aliased]) -> [T]{
        guard let dataPoint = self.dataPoint else{
            return [T]()
        }
        let UIDs = aliases.map { $0.uid }
        let instances = dataPoint.registredModelByUIDs(UIDs)
        guard let castedInstances = instances as? [T] else{
            return [T]()
        }
        return castedInstances
    }

}
