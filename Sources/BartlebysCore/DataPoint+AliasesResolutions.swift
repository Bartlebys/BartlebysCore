//
//  DataPoint+AliasesResolutions.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 08/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

extension DataPoint:AliasesResolution{
    
    /// Resolves the alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func instance<T : Codable & Collectable >(from alias:Aliased) throws -> T{
        // We want to be able to resolve any object not only Models and ManagedModels
        // So we use the opaque layer.
        let instance =  self.registredOpaqueInstanceByUID(alias.UID)
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
    public func instances<T : Codable  & Collectable  >(from aliases:[Aliased]) throws -> [T] {
        let UIDs = aliases.map { $0.UID }
        let instances:[T] = try self.registredObjectsByUIDs(UIDs)
        return instances
    }

    // MARK: - Optionals

    /// Resolves the optional instances alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func optionalInstance<T : Codable  & Collectable >(from alias:Aliased) -> T?{
        return  self.registredOpaqueInstanceByUID(alias.UID) as? T
    }


    /// Resolves the optionals aliases
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    public func optionalInstances<T : Codable >(from aliases:[Aliased]) -> [T]{

        let UIDs = aliases.map { $0.UID }
        let instances = self.registredOpaqueInstancesByUIDs(UIDs)
        guard let castedInstances = instances as? [T] else{
            return [T]()
        }
        return castedInstances
    }

}