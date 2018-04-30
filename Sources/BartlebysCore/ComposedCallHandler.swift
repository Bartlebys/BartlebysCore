//
//  ComposedCallHandler.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 27/04/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


class ComposedCallHandler<P, R>  where P : Payload, R : Result & Collectable{

    fileprivate var _composedHandlers:[(CallOperation,HTTPResponse?,Error?)->()] = [(CallOperation<P,R>,HTTPResponse?,Error?)->()]()

    public func addAnHandler(_ handler:@escaping(CallOperation<P,R>,HTTPResponse?,Error?)->()){
        self._composedHandlers.append(handler)
    }

    public lazy var callHandler:(CallOperation<P,R>,HTTPResponse?,Error?)->() = { operation, response, error in
        for subHandler in self._composedHandlers{
            subHandler(operation,response,error)
        }
    }
}
