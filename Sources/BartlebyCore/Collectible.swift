//
//  Collectible.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public protocol Collectible : UniversalType {

    // Universally Unique identifier (check Globals.swift for details on the primary key MODELS_PRIMARY_KEY)
    var id:String { get set }

}

