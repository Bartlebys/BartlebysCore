//
//  AliasOf.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 07/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

/// The generic alias class
open class AliasOf<T:Aliasable>: Object, Codable,Aliased{

    public let uid:UID
    
    public required init(uid:UID) {
        self.uid = uid
    }

    // MARK: - Codable

    // We use the MODELS_PRIMARY_KEY because we want to be able define if the id is encoded as `_id` or `id`

    public required init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: CodableObject.CodableModelCodingKeys.self)
        self.uid = try values.decode(String.self,forKey:MODELS_PRIMARY_KEY)
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:  CodableObject.CodableModelCodingKeys.self)
        try container.encode(self.uid,forKey:MODELS_PRIMARY_KEY)
    }

}
