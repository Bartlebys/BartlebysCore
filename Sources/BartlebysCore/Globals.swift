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
public var MODELS_PRIMARY_KEY: CodableObject.CodableModelCodingKeys = CodableObject.CodableModelCodingKeys.id

// the explicit UID type used for expressivity
public typealias UID = String

// By default, the UIDs are base64 encoded to be compliant with MongodB ids
public var BASE64_ENCODED_UIDS = true

// A flag to distinguish non provisioned call operation
public let ORDER_OF_EXECUTION_UNDEFINED:Int = -1

// MARK: - Time

// The start Time is define when launching.
fileprivate let _startTime = AbsoluteTimeGetCurrent()

/// Returns the elapsed time since launch time.
///
/// - Returns: the elapsed tile
public func getElapsedTime()->Double {
    return AbsoluteTimeGetCurrent() - _startTime
}

/// Measure the execution duration of a given block
///
///   - execute: the execution block to be evaluated
/// - Returns: the execution time
public func measure(_ execute: () throws -> Void) rethrows -> Double {
    let ts = AbsoluteTimeGetCurrent()
    try execute()
    return (AbsoluteTimeGetCurrent()-ts)
}

// MARK: - Main Thread 

public func syncOnMain(execute block: () throws -> Void) rethrows-> (){
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

