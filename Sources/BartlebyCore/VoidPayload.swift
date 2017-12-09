//
//  voidPayload.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 05/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public struct VoidPayload : Payload {
    
    public var id: String = Utilities.createUID()

    public static var collectionName: String {
        return "voidPayloads"
    }

    public var d_collectionName: String{
        return VoidPayload.collectionName
    }

    public static var typeName: String {
        return "VoidPayload"
    }

    public init() {
        
    }
}
