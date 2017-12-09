//
//  ManagedModel+Helpers.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 13/11/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

extension Model{

    public static func ==(lhs: Model, rhs: Model) -> Bool {
        return lhs.id==rhs.id
    }
}



