//
//  Object.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation
import Dispatch

/*
 NOTES @todo Bartleby Fusion
 - Server side : Primary is now encoded using "id" not "_id" (this may have a large impact server side.
 - We always use Model:Object as ancestor to implement by hand core behaviour.
 - Consequently we have replaced variable $inheritancePrefix in the generative blocks
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

    open class Object : NSObject{}

    public typealias CopyingProtocol = NSCopying

    public func AbsoluteTimeGetCurrent()->Double{
        return Double(CFAbsoluteTimeGetCurrent())
    }

    public func random<T: BinaryInteger> (_ n: T) -> T {
        return numericCast( arc4random_uniform( numericCast(n) ) )
    }


#elseif os(Linux)

    import Glibc

    open class Object : NSObject {}

    public protocol CopyingProtocol {}

    public func AbsoluteTimeGetCurrent()->Double{
        return 0 // @todo linux
    }

    public func random<T: BinaryInteger> (_ n: T) -> T {
        precondition(n > 0)

        let upperLimit = RAND_MAX - RAND_MAX % numericCast(n)

        while true {
            let x = Glibc.random()
            if x < upperLimit { return numericCast(x) % n }
        }
    }

#endif

public extension Object{

    // MARK: - Thread Safety?

    public static func syncOnMain(execute block: () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }

    public static func syncThrowableOnMain(execute block: () throws -> Void) rethrows-> (){
        if Thread.isMainThread {
            try block()
        } else {
            try DispatchQueue.main.sync(execute: block)
        }
    }

    public static func syncOnMainAndReturn<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }

}

