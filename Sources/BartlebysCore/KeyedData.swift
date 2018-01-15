//
//  KeyedData.swift
//  Bartleby
//
// THIS FILE AS BEEN GENERATED BY BARTLEBYFLEXIONS for Benoit Pereira da Silva https://pereira-da-silva.com/contact
// DO NOT MODIFY THIS FILE YOUR MODIFICATIONS WOULD BE ERASED ON NEXT GENERATION!
//
// Copyright (c) 2016  https://bartlebys.org  All rights reserved.
//

import Foundation

#if os(macOS) && USE_COCOA_BINDINGS
public typealias KeyedData = DynamicKeyedData
#else
public typealias KeyedData = CommonKeyedData
#endif

// MARK: A simple wrapper to associate a key and a Data
open class CommonKeyedData:Model{

    public typealias CollectedType = KeyedData

	//The key
	open var key:String = Default.NO_KEY

	//The Data
	open var data:Data = Data()


    // MARK: - Codable


    public enum KeyedDataCodingKeys: String,CodingKey{
		case key
		case data
    }

    required public init(from decoder: Decoder) throws{
		try super.init(from: decoder)
        try self.quietThrowingChanges {
			let values = try decoder.container(keyedBy: KeyedDataCodingKeys.self)
			self.key = try values.decode(String.self,forKey:.key)
			self.data = try values.decode(Data.self,forKey:.data)
        }
    }

    override open func encode(to encoder: Encoder) throws {
		try super.encode(to:encoder)
		var container = encoder.container(keyedBy: KeyedDataCodingKeys.self)
		try container.encode(self.key,forKey:.key)
		try container.encode(self.data,forKey:.data)
    }



    // MARK: - Initializable

    required public init() {
        super.init()
    }

    // MARK: - UniversalType

    override  open class var typeName:String{
        return "KeyedData"
    }

    override  open class var collectionName:String{
        return "keyedDatas"
    }

    override  open var d_collectionName:String{
        return KeyedData.collectionName
    }
}



#if os(macOS)

// You Can use Dynamic Override to support Cocoa Bindings
// This class can be used in a CollectionOf<T>

@objc open class DynamicKeyedData:CommonKeyedData{

    @objc override dynamic open var  key : String{
        set{ super.key = newValue }
        get{ return super.key }
    }

    @objc override dynamic open var  data : Data{
        set{ super.data = newValue }
        get{ return super.data }
    }
}

#endif