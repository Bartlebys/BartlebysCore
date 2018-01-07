//
//  Model+AliasesResolution.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

extension Model:AliasesResolution{

    /// Resolves the alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func instance<T : Codable >(from alias:Aliased) throws -> T{
        guard let dataPoint = self.dataPoint else{
            throw AliasResolverError.undefinedContainer
        }
        // We want to be able to resolve any object not only Models and ManagedModels
        // So we use the opaque layer.
        let instance =  dataPoint.registredOpaqueInstanceByUID(alias.UID)
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
    public func instances<T : Codable >(from aliases:[Aliased]) throws -> [T] {
        guard let dataPoint = self.dataPoint else{
            throw AliasResolverError.undefinedContainer
        }
        let UIDs = aliases.map { $0.UID }
        let instances = dataPoint.registredOpaqueInstancesByUIDs(UIDs)
        guard  instances.count == UIDs.count else {
            throw AliasResolverError.notFound
        }
        guard let castedInstances = instances as? [T] else{
            throw AliasResolverError.typeMissMatch
        }
        return castedInstances
    }

    // MARK: - Optionals

    /// Resolves the optional instances alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func optionalInstance<T : Codable >(from alias:Aliased) -> T?{
        guard let dataPoint = self.dataPoint else{
            return nil
        }
        return  dataPoint.registredOpaqueInstanceByUID(alias.UID) as? T
    }


    /// Resolves the optionals aliases
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    public func optionalInstances<T : Codable >(from aliases:[Aliased]) -> [T]{
        guard let dataPoint = self.dataPoint else{
            return [T]()
        }
        let UIDs = aliases.map { $0.UID }
        let instances = dataPoint.registredOpaqueInstancesByUIDs(UIDs)
        guard let castedInstances = instances as? [T] else{
            return [T]()
        }
        return castedInstances
    }

}
