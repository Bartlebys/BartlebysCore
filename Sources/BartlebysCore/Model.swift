//
//  Model.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

open class Model:Object,Collectable,Codable,CopyingProtocol,Payload{

    // If set to false the ownedBy instances & freeRelations will not be serialized
    // Can be used to inject some Model into Systems that does not support Bartlebys Relational model
    static public var encodeRelations:Bool = true

    // MARK: - Collectable

    // The id 
    @objc dynamic public var id:UID = Utilities.createUID()

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

    // MARK: Collectable.Identifiable

    @objc dynamic public var UID:UID {
        set{
            self.id = UID
        }
        get{
            return self.id
        }
    }


    // MARK: -

    // The collection reference.
    fileprivate var _collection:Any?

    ////Internal flag used not to propagate changes (for example during deserialization) -> Check + ProvisionChanges for detailled explanantions
    internal var _quietChanges:Bool = false


    /// The type erased Collection part of BartlebyKit's Commitable procotol
    public var managedCollection:ManagedCollection? {
        return self._collection as? ManagedCollection
    }

    // MARK: - Properties used for Relational Model

    //The UIDS of the owners
    @objc dynamic open var ownedBy:[String] = [String]()  {
        didSet {
            if !self.wantsQuietChanges && ownedBy != oldValue {
                self.indistinctCollection?.didChange()
            }
        }
    }

    //The UIDS of the free relations
    @objc dynamic open var freeRelations:[String] = [String]()  {
        didSet {
            if !self.wantsQuietChanges && ownedBy != oldValue {
                self.indistinctCollection?.didChange()
            }
        }
    }

    //The UIDS of the owned entities (Neither supervised nor serialized check appendToDeferredOwnershipsList for explanations)
    @objc dynamic open var owns:[String] = [String]()



    // MARK: - Initializable
    
    required public override init() {
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
        super.init()
        let values = try decoder.container(keyedBy: ModelCodingKeys.self)
        // We want to be resilient to external omissions
        // So we discriminate the invalid UIDs by prefixing NO_UID
        // We admit not to have ownedBy and freeRelations Keys
        self.id = try values.decodeIfPresent(String.self,forKey:MODELS_PRIMARY_KEY) ?? Default.NO_UID + self.id
        self.ownedBy =? try values.decodeIfPresent([String].self,forKey: .ownedBy)
        self.freeRelations =? try values.decodeIfPresent([String].self, forKey: .freeRelations)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ModelCodingKeys.self)
        try container.encode(self.id,forKey:MODELS_PRIMARY_KEY)
        if Model.encodeRelations{
            try container.encode(self.ownedBy,forKey: .ownedBy)
            try container.encode(self.freeRelations,forKey:.freeRelations)
        }
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

    // MARK: - Partial implementation of BarltebyKit's ProvisionChanges for Generative compatibility

    /// Performs the deserialization without invoking provisionChanges
    ///
    /// - parameter changes: the changes closure
    public func quietThrowingChanges(_ changes:()throws->())rethrows{
        self._quietChanges=true
        try changes()
        self._quietChanges=false
    }


    /// the Accessor to the underlining quiet state
    public var wantsQuietChanges:Bool{
        return self._quietChanges
    }

    /// Performs the deserialization without invoking provisionChanges
    ///
    /// - parameter changes: the changes closure
    public func quietChanges(_ changes: () -> ()) {
        self._quietChanges=true
        changes()
        self._quietChanges=false
    }

}



