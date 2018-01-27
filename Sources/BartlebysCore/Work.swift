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
    public let interval: TimeInterval

    var dispatchTime: DispatchTime {
        return DispatchTime(uptimeNanoseconds: UInt64(interval * Double(NSEC_PER_SEC)))
    }

    public init(dispatchWorkItem: DispatchWorkItem, interval: TimeInterval, associatedUID:UID = Default.NO_UID  ) {
        self.dispatchWorkItem = dispatchWorkItem
        self.interval = interval
        self.associatedUID = associatedUID
        DispatchQueue.main.asyncAfter(deadline: self.dispatchTime, execute: self.dispatchWorkItem)
    }

    func cancel() {
        self.dispatchWorkItem.cancel()
    }
}
