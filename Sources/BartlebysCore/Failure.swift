//
//  Failure.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public struct Failure {

    public var httpResponse: HTTPResponse?
    public var error: Error?

    public init(from error:Error) {
        self.error = error
    }

    public init(from response:HTTPResponse) {
        self.httpResponse = response
        self.error = nil
    }

    public init(from response:HTTPResponse, and error:Error?) {
        self.httpResponse = response
        self.error = error
    }
}
