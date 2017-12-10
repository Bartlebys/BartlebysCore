//
//  Tolerent.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public protocol Tolerent {

    /// You should implement this protocol on any Codable object
    /// If you want to be able to fix conformity or versioning issues on deserialization.
    ///
    /// - Parameter dictionary: the dictionary
    static func patchDictionary(_ dictionary: inout Dictionary<String, Any>)


    // @bpds @todo: we should implement a symetric method
    //func transFormToDictionaryRepresantation()

}
