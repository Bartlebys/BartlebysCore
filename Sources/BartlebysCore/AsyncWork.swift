//
//  AsyncWork.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

/// Async Cancellable Work
public struct AsyncWork {

    public fileprivate(set) var associatedUID:UID

    public let dispatchWorkItem: DispatchWorkItem
    public let delay: TimeInterval

    public var dispatchTime: DispatchTime {
        let now: UInt64 = DispatchTime.now().uptimeNanoseconds
        return DispatchTime(uptimeNanoseconds: now + UInt64(self.delay * Double(NSEC_PER_SEC)))
    }


    /// Work runs automatically on instanciation
    ///
    /// - Parameters:
    ///   - dispatchWorkItem: the CGD DispatchWorkItem
    ///   - delay: the delay before execution
    ///   - associatedUID: the associated UID
    ///   - queue: the execution queue
    public init(dispatchWorkItem: DispatchWorkItem, delay: TimeInterval, associatedUID:UID = Default.NO_UID, queue: DispatchQueue = DispatchQueue.main) {
        self.dispatchWorkItem = dispatchWorkItem
        self.delay = delay
        self.associatedUID = associatedUID
        if delay > 0{
            queue.asyncAfter(deadline: self.dispatchTime, execute: self.dispatchWorkItem)
        }else{
            queue.async(execute: self.dispatchWorkItem)
        }
    }

    public func cancel() {
        self.dispatchWorkItem.cancel()
    }
}
