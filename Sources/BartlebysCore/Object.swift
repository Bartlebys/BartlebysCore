//
//  Object.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

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


#elseif os(Linux)

    open class Object {}

    public protocol CopyingProtocol {}

    public func AbsoluteTimeGetCurrent()->Double{
        return Double(CFAbsoluteTimeGetCurrent())
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

