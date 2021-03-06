//
//  Globals.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation
import Dispatch

// Bartleby 1.0 for MongodB (can be set-up uses CodableObject.CodableModelCodingKeys._id)
// In Most context Model.ModelCodingKeys.id is relevant.
public var MODELS_PRIMARY_KEY: CodableObject.CodableModelCodingKeys = CodableObject.CodableModelCodingKeys.id


// the explicit UID type used for expressivity
public typealias UID = String

// By default, the UIDs are base64 encoded to be compliant with MongodB ids
public var BASE64_ENCODED_UIDS:Bool = true

// A flag to distinguish non provisioned call operation
public let ORDER_OF_EXECUTION_UNDEFINED:Int = -1

// MARK: - Time

// The start Time is define when launching.
fileprivate let _startTime: Double = AbsoluteTimeGetCurrent()

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
    let ts: Double = AbsoluteTimeGetCurrent()
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


public func combineHashes(_ hashes: [Int]) -> Int {
    return hashes.reduce(0, combineHashValues)
}

public func combineHashValues(_ initial: Int, _ other: Int) -> Int {
    #if arch(x86_64) || arch(arm64)
    let magic: UInt = 0x9e3779b97f4a7c15
    #elseif arch(i386) || arch(arm)
    let magic: UInt = 0x9e3779b9
    #endif
    var lhs = UInt(bitPattern: initial)
    let rhs = UInt(bitPattern: other)
    lhs ^= rhs &+ magic &+ (lhs << 6) &+ (lhs >> 2)
    return Int(bitPattern: lhs)
}



public func doCatchLog(_ block: @escaping() throws -> Void, category: LogEntry.Category = .standard, file: String = #file, function: String = #function, line: Int = #line, decorative: Bool = false){
    do{
        try block()
    } catch{
        Logger.log("\(error)", category: category,file: file,function: function, line: line,decorative: decorative)
    }
}
