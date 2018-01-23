//
//  Globals.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation
import Dispatch

// Bartleby 1.0 for MongodB (can be set-up uses Model.ModelCodingKeys._id)
// In Most context Model.ModelCodingKeys.id is relevant.
public var MODELS_PRIMARY_KEY:CodableObject.CodableModelCodingKeys = CodableObject.CodableModelCodingKeys.id

// Used to define the root item key
// Should be set to  CollectionOf.CollectionCodingKeys._storage or  CollectionOf.CollectionCodingKeys.items
public var COLLECTION_ITEMS_KEY:CollectionOfCodingKeys = CollectionOfCodingKeys.items


// the explicit UID type used for expressivity
public typealias UID = String

// MARK: - Time

// The start Time is define when launching.
fileprivate let _startTime = AbsoluteTimeGetCurrent()

/// Returns the elapsed time since launch time.
///
/// - Returns: the elapsed tile
public func getElapsedTime()->Double {
    return AbsoluteTimeGetCurrent() - _startTime
}

// MARK: - Main Thread 

public func syncOnMain(execute block: () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
}

public func syncThrowableOnMain(execute block: () throws -> Void) rethrows-> (){
    if Thread.isMainThread {
        try block()
    } else {
        try DispatchQueue.main.sync(execute: block)
    }
}

public func syncOnMainAndReturn<T>(execute work: () throws -> T) rethrows -> T {
    if Thread.isMainThread {
        return try work()
    } else {
        return try DispatchQueue.main.sync(execute: work)
    }
}

