//
//  ManagedModel.swift
//  LaPlayList
//
// THIS FILE AS BEEN GENERATED BY BARTLEBYFLEXIONS for Benoit Pereira da Silva https://pereira-da-silva.com/contact 
// DO NOT MODIFY THIS FILE YOUR MODIFICATIONS WOULD BE ERASED ON NEXT GENERATION!
//
// Copyright (c) 2016  MusicWork https://music-work.com  All rights reserved.
//
import Foundation
#if !USE_EMBEDDED_MODULES
	#endif

// MARK: Bartleby's Core base Managed Entity
open class ManagedModel:Model{

	//An external unique identifier
	@objc dynamic open var externalID:String? {
	    didSet { 
	       if !self.wantsQuietChanges && externalID != oldValue {
	            self.provisionChanges(forKey: "externalID",oldValue: oldValue,newValue: externalID) 
	       } 
	    }
	}

	//The UIDS of the owners
	@objc dynamic open var ownedBy:[String] = [String]()  {
	    didSet { 
	       if !self.wantsQuietChanges && ownedBy != oldValue {
	            self.provisionChanges(forKey: "ownedBy",oldValue: oldValue,newValue: ownedBy)  
	       } 
	    }
	}

	//The UIDS of the free relations
	@objc dynamic open var freeRelations:[String] = [String]()  {
	    didSet { 
	       if !self.wantsQuietChanges && freeRelations != oldValue {
	            self.provisionChanges(forKey: "freeRelations",oldValue: oldValue,newValue: freeRelations)  
	       } 
	    }
	}

	//The UIDS of the owned entities (Neither supervised nor serialized check appendToDeferredOwnershipsList for explanations)
	@objc dynamic open var owns:[String] = [String]()

    // Base Object implementation
    // MARK: - Codable


    public enum ManagedModelCodingKeys: String,CodingKey{
		case externalID
		case ownedBy
		case freeRelations
		case owns
		case typeName
    }

    required public init(from decoder: Decoder) throws{
		super.init()
        try self.quietThrowingChanges {
			let values = try decoder.container(keyedBy: ManagedModelCodingKeys.self)
			self.externalID = try values.decodeIfPresent(String.self,forKey:.externalID)
        }
    }

    override open func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: ManagedModelCodingKeys.self)
		try container.encodeIfPresent(self.externalID,forKey:.externalID)
    }


    // MARK: - Initializable

    required public init() {
        super.init()
    }

    // MARK: - UniversalType

    override  open class var typeName:String{
        return "ManagedModel"
    }

    override  open class var collectionName:String{
        return "managedModels"
    }

    override  open var d_collectionName:String{
        return ManagedModel.collectionName
    }
}
