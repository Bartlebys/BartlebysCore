//
//  Committable.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 02/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public protocol Committable {

    // MARK: Commit

    // You can in specific situation mark that an instance should be committed by calling this method.
    // For example after a bunch of unSupervised changes.
    func needsToBeCommitted()

    // Marks the entity as committed and increments it provisionning counter
    func hasBeenCommitted()

    // Returns the current commit counter
    var commitCounter:Int { get }

    // MARK: Changes

    /// Perform changes without commit
    ///
    /// - parameter changes: the changes
    func doNotCommit(_ changes:()->())

    /// The collection with erased types
    var parentCollection:ManagedCollection? { get }
}
