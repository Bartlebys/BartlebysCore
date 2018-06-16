//
//  Model+Helpers.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 13/11/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

extension Model{

    // We have encountered serious QUIRKS With `Equatable` + OBJC runtime (with swift 4)
    // Such inconsistencies or bugs where very difficult to debug o
    // So we have decided to create global functions equalityOf(...)
    // The Equatable implementation relies on this function

    public static func ==(lhs: Model, rhs: Model) -> Bool {
        return equalityOf(lhs, rhs)
    }
}

public func equalityOf(_ lhs: Model?, _ rhs: Model?) -> Bool {
    let equality = lhs?.uid == rhs?.uid
    return equality
}

