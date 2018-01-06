//
//  Alias.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


/// The alias struct
public struct Alias:Codable{

    // We use
    public let UID:UID

    public init(UID:UID) {
        self.UID = UID
    }

    // MARK: - Codable

    // We use the Model.ModelCodingKeys because we want to be able define if the id is encoded as `_id` or `id`

    public init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: Model.ModelCodingKeys.self)
        self.UID = try values.decode(String.self,forKey:BartlebysCore.MODELS_PRIMARY_KEY)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:  Model.ModelCodingKeys.self)
        try container.encode(self.UID,forKey:BartlebysCore.MODELS_PRIMARY_KEY)
    }

}
