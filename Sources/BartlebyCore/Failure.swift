//
//  Failure.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
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
