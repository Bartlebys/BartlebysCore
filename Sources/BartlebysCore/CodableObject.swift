//
//  CodableObject.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 18/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

open class CodableObject:Object,Codable,Identifiable,CopyingProtocol{

    // The id
    public var id:UID = Utilities.createUID()

    // MARK: Collectable.Identifiable

    public var UID:UID {
        set{
            self.id = UID
        }
        get{
            return self.id
        }
    }

    // MARK: - Initializable

    required public override init() {
        super.init()
    }

    // MARK: - Codable

    public enum CodableModelCodingKeys: String,CodingKey{
        case id     // the concrete selected value is defined by MODELS_PRIMARY_KEY
        case _id    // the concrete selected value is defined by MODELS_PRIMARY_KEY
    }

    public required init(from decoder: Decoder) throws{
        super.init()
        let values = try decoder.container(keyedBy: CodableModelCodingKeys.self)
        // We want to be resilient to external omissions
        // So we discriminate the invalid UIDs by prefixing NO_UID
        // We admit not to have ownedBy and freeRelations Keys
        self.id = try values.decodeIfPresent(String.self,forKey:MODELS_PRIMARY_KEY) ?? Default.NO_UID + self.id
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodableModelCodingKeys.self)
        try container.encode(self.id,forKey:MODELS_PRIMARY_KEY)
    }


    /// MARK: - CustomStringConvertible

    open override var description: String {
        do{
            let data =  try JSON.prettyEncoder.encode(self)
            if let json = String(data:data,encoding:.utf8){
                return json
            }
        }catch{
            return "\(error)"
        }
        return "Description is not available"
    }


    // MARK: - NSCopy aka CopyingProtocol

    public func copy(with zone: NSZone? = nil) -> Any {
        guard let data = try? JSON.encoder.encode(self) else {
            return Model()
        }
        guard let copy = try? JSON.decoder.decode(type(of:self), from: data) else {
            return Model()
        }
        return copy
    }

}
