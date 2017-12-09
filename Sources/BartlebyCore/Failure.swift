//
//  Failure.swift
//  LPSynciOS
//
//  Created by Laurent Morvillier on 08/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public struct Failure {

    public var httpStatus: Status?
    public var error: Error?

    public init(from error:Error) {
        self.error = error
        self.httpStatus = Status.undefined
    }

    public init(from status:Status) {
        self.httpStatus = status
        self.error = nil
    }

    public init(from status:Status, and error:Error) {
        self.httpStatus = status
        self.error = nil
    }
}
