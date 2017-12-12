//
//  Model.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

final class Download : Model, Tolerent {
    
    static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        
    }
    
}

final class Upload : Model, Tolerent {
    
    static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        
    }
    
}

open class Model:Object,Codable,Collectible,CopyingProtocol,Payload{

    // Compatibility layer
    @objc dynamic public var UID:String {
        set{
            self.id = UID
        }
        get{
            return self.id
        }
    }

    @objc dynamic public var id:String = Utilities.createUID()

    internal var _quietChanges:Bool = false

    internal var _autoCommitIsEnabled:Bool = true

    // MARK: - Initializable

    required public override init() {
        super.init()
    }

    // MARK: - Codable

    public enum ModelCodingKeys: String,CodingKey{
        case id     // the concrete selected value is defined by MODELS_PRIMARY_KEY
        case _id    // the concrete selected value is defined by MODELS_PRIMARY_KEY
    }

    public required init(from decoder: Decoder) throws{
        super.init()
        try self.quietThrowingChanges {
            let values = try decoder.container(keyedBy: ModelCodingKeys.self)
            self.id = try values.decode(String.self,forKey:MODELS_PRIMARY_KEY)
        }
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ModelCodingKeys.self)
        try container.encode(self.id,forKey:MODELS_PRIMARY_KEY)
    }
    // MARK: - UniversalType

    open class var typeName:String{
        return "Model"
    }

    open class var collectionName:String{
        return "models"
    }

    open var d_collectionName:String{
        return Model.collectionName
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



