//
//  Object.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

    open class Object : NSObject{}

#elseif os(Linux)

    open class Object : NSObject {}

#endif

public enum ObjectError:Error {
    case message(message:String)
}
