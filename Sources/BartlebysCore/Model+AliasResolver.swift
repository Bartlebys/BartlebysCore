//
//  Model+AliasResolver.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

extension Model:AliasResolver{

    /// Resolve the alias
    ///
    /// - Parameter alias: the alias
    /// - Returns: the reference
    public func instance<T : Codable >(from alias:Alias)->T?{
        // We want to be able to resolve any object not only Models and ManagedModels
        // So we use the opaque layer.
        return self.dataPoint?.registredOpaqueInstanceByUID(alias.UID) as? T
    }

}
