//
//  Work.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public struct Work {

    public fileprivate(set) var associatedUID:UID

    public let dispatchWorkItem: DispatchWorkItem
    public let delay: TimeInterval

    var dispatchTime: DispatchTime {
        return DispatchTime(uptimeNanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
    }


    /// Work runs automatically on instanciation
    ///
    /// - Parameters:
    ///   - dispatchWorkItem: the CGD DispatchWorkItem
    ///   - delay: the delay before execution
    ///   - associatedUID: the associated UID
    public init(dispatchWorkItem: DispatchWorkItem, delay: TimeInterval, associatedUID:UID = Default.NO_UID  ) {
        self.dispatchWorkItem = dispatchWorkItem
        self.delay = delay
        self.associatedUID = associatedUID
        DispatchQueue.main.asyncAfter(deadline: self.dispatchTime, execute: self.dispatchWorkItem)
    }

    func cancel() {
        self.dispatchWorkItem.cancel()
    }
}
