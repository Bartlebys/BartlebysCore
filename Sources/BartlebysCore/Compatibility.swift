//
//  Compatibility.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 20/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation
#if os(Linux)
    import Glibc
#endif

// We store in this file the Compatibility Adjustments.
// We want to provide a consistent stack on any Platform.

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

    public typealias CopyingProtocol = NSCopying

    public func AbsoluteTimeGetCurrent()->Double{
        return Double(CFAbsoluteTimeGetCurrent())
    }

    public func random<T: BinaryInteger> (_ n: T) -> T {
        return numericCast( arc4random_uniform( numericCast(n) ) )
    }

#elseif os(Linux)

    public protocol CopyingProtocol {}

    public func AbsoluteTimeGetCurrent()->Double{
        return 0 // @todo linux
    }

    public class Progress {
        public var totalUnitCount: Int64 = 0
        public var completedUnitCount: Int64 = 0
        public init(){}
    }

    public func NSLocalizedString(_ key: String, tableName: String, comment: String) -> String{
        return key   // @Todo Linux
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


