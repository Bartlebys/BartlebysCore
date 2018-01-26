//
//  Model.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

open class Model:CodableObject,Collectable{

    // If set to false the ownedBy instances & freeRelations will not be serialized
    // Can be used to inject some Model into Systems that does not support Bartlebys Relational model
    static public var encodeRelations:Bool = true

    // MARK: - Collectable

    // A reference to the holding dataPoint
    public var dataPoint:DataPoint?

    /// Sets the dataPoint Reference
    ///
    /// - Parameter dataPoint: the dataPoint
    public func setDataPoint(_ dataPoint:DataPoint){
        self.dataPoint = dataPoint
    }

    public typealias CollectedType = Model

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

    /// The type erased acceessor to a collection that support reference, remove & didChange
    public var indistinctCollection:IndistinctCollection?{
        return self._collection as? IndistinctCollection
    }

    // MARK: Collectable.UniversalType

    open class var typeName:String{
        return "Model"
    }

    open class var collectionName:String{
        return "models"
    }

    open var d_collectionName:String{
        return Model.collectionName
    }


    // MARK: -

    // The collection reference.
    fileprivate var _collection:Any?


    /// The type erased Collection part of BartlebyKit's Commitable procotol
    public var managedCollection:ManagedCollection? {
        return self._collection as? ManagedCollection
    }

    // MARK: - Properties used for Relational Model

    //The UIDS of the owners
    open var ownedBy:[UID] = [String]()  {
        didSet {
            if !self.wantsQuietChanges && ownedBy != oldValue {
                self.indistinctCollection?.didChange()
            }
        }
    }

    //The UIDS of the free relations
    open var freeRelations:[UID] = [String]()  {
        didSet {
            if !self.wantsQuietChanges && ownedBy != oldValue {
                self.indistinctCollection?.didChange()
            }
        }
    }

    //The UIDS of the owned entities (Neither supervised nor serialized check appendToDeferredOwnershipsList for explanations)
    open var owns:[UID] = [String]()



    // MARK: - Initializable
    
    required public init() {
        super.init()
    }
    
    // MARK: - Codable
    
    public enum ModelCodingKeys: String,CodingKey{
        case id     // the concrete selected value is defined by MODELS_PRIMARY_KEY
        case _id    // the concrete selected value is defined by MODELS_PRIMARY_KEY
        case ownedBy
        case freeRelations
        case owns // not serialized
    }
    
    public required init(from decoder: Decoder) throws{
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: ModelCodingKeys.self)
        self.ownedBy =? try values.decodeIfPresent([String].self,forKey: .ownedBy)
        self.freeRelations =? try values.decodeIfPresent([String].self, forKey: .freeRelations)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: ModelCodingKeys.self)
        if Model.encodeRelations{
            try container.encode(self.ownedBy,forKey: .ownedBy)
            try container.encode(self.freeRelations,forKey:.freeRelations)
        }
    }



}



