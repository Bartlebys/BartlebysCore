//
//  AliasOf.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 07/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

/// The generic alias class
open class AliasOf<T:Aliasable>:Codable,Aliased{

    public let UID:UID
    
    public required init(UID:UID) {
        self.UID = UID
    }

    // MARK: - Codable

    // We use the Model.ModelCodingKeys because we want to be able define if the id is encoded as `_id` or `id`

    public required init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: CodableObject.CodableModelCodingKeys.self)
        self.UID = try values.decode(String.self,forKey:MODELS_PRIMARY_KEY)
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:  CodableObject.CodableModelCodingKeys.self)
        try container.encode(self.UID,forKey:MODELS_PRIMARY_KEY)
    }

}
