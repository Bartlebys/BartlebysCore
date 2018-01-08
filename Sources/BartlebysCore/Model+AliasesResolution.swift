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
    public func instance<T : Codable & Collectable >(from alias:Aliased) throws -> T{
        guard let dataPoint = self.dataPoint else{
            throw AliasResolverError.undefinedContainer
        }
        return try dataPoint.instance(from: alias)
    }



    /// Resolves the aliases
    /// Verify that all the instance are available
    /// May throw AliasResolverError
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    /// - Throws: AliasResolverError
    public func instances<T : Codable  & Collectable  >(from aliases:[Aliased]) throws -> [T] {
        guard let dataPoint = self.dataPoint else{
            throw AliasResolverError.undefinedContainer
        }
        return try dataPoint.instances(from: aliases)
    }

    // MARK: - Optionals

    /// Resolves the optional instances alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func optionalInstance<T : Codable  & Collectable >(from alias:Aliased) -> T?{
        guard let dataPoint = self.dataPoint else{
            return nil
        }
        return dataPoint.optionalInstance(from: alias)
    }

    /// Resolves the optional instance alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    /// - Throws: AliasResolverError
    public func optionalInstance<T : Codable & Collectable>(from alias:Aliased?) -> T?{
        guard let alias = alias,let dataPoint = self.dataPoint else{
            return nil
        }
        return dataPoint.optionalInstance(from: alias)
    }

    /// Resolves the optionals aliases
    ///
    /// - Parameter aliases: the aliases
    /// - Returns: the references
    public func optionalInstances<T : Codable >(from aliases:[Aliased]) -> [T]{
        guard let dataPoint = self.dataPoint else{
            return [T]()
        }
        return dataPoint.optionalInstances(from: aliases)
    }

}
