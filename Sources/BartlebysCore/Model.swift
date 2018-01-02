//
//  Model.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

open class Model:Object,Codable,BartlebysCore.Collectible,CopyingProtocol,Payload{

    // A reference to the holding dataPoint
    public var dataPoint:DataPoint?

    /// Sets the dataPoint Reference
    ///
    /// - Parameter dataPoint: the dataPoint
    public func setDataPoint(_ dataPoint:DataPoint){
        self.dataPoint = dataPoint
    }

    // MARK: - Collection support

    public typealias CollectedType = Model

    // The collection reference.
    fileprivate var _collection:Any?

    ////Internal flag used not to propagate changes (for example during deserialization) -> Check + ProvisionChanges for detailled explanantions
    internal var _quietChanges:Bool = false

    /// Registers the collection reference
    ///
    /// - Parameter collection: the collection
    public func setCollection<CollectedType>(_ collection:CollectionOf<CollectedType>){
        self._collection = collection
    }

    /// Returns the collection
    ///
    /// - Returns: the collection
    public func getCollection<CollectedType>()->CollectionOf<CollectedType>{
        guard let collection = self._collection as? CollectionOf<CollectedType> else{
            // Return a proxy (should not normally occur)
            return CollectionOf<CollectedType>(named: "ProxyCollectionOf<\(CollectedType.typeName)>", relativePath: "")
        }
        return collection
    }

    /// The type erased Collection
    public var collection:E_Collection? {
        return self._collection as? E_Collection
    }

    // MARK: - Identifiable

    @objc dynamic public var UID:UID {
        set{
            self.id = UID
        }
        get{
            return self.id
        }
    }

    // MARK: -

    @objc dynamic public var id:UID = Utilities.createUID()


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
        let values = try decoder.container(keyedBy: ModelCodingKeys.self)
        self.id = try values.decode(String.self,forKey:BartlebysCore.MODELS_PRIMARY_KEY)
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ModelCodingKeys.self)
        try container.encode(self.id,forKey:BartlebysCore.MODELS_PRIMARY_KEY)
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



