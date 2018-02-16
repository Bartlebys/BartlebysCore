//
//  FilePath.swift
//  Bartleby
//
// THIS FILE AS BEEN GENERATED BY BARTLEBYFLEXIONS for Benoit Pereira da Silva https://pereira-da-silva.com/contact
// DO NOT MODIFY THIS FILE YOUR MODIFICATIONS WOULD BE ERASED ON NEXT GENERATION!
//
// Copyright (c) 2016  https://bartlebys.org  All rights reserved.
//

import Foundation

#if os(macOS) && USE_COCOA_BINDINGS
public typealias FilePath = DynamicFilePath
#else
public typealias FilePath = CommonFilePath
#endif

// MARK: Bartleby's Core: a file path reference
open class CommonFilePath : Model, Payload, Result{

    public typealias CollectedType = FilePath

	//The file relative path
	open var relativePath:String = Default.NOT_SPECIFIED


    // MARK: - Codable


    public enum FilePathCodingKeys: String,CodingKey{
		case relativePath
    }

    required public init(from decoder: Decoder) throws{
		try super.init(from: decoder)
        try self.quietThrowingChanges {
			let values = try decoder.container(keyedBy: FilePathCodingKeys.self)
			self.relativePath = try values.decode(String.self,forKey:.relativePath)
        }
    }

    override open func encode(to encoder: Encoder) throws {
		try super.encode(to:encoder)
		var container = encoder.container(keyedBy: FilePathCodingKeys.self)
		try container.encode(self.relativePath,forKey:.relativePath)
    }



    // MARK: - Initializable

    required public init() {
        super.init()
    }

    // MARK: - UniversalType

    override  open class var typeName:String{
        return "FilePath"
    }

    override  open class var collectionName:String{
        return "filePaths"
    }

    override  open var d_collectionName:String{
        return FilePath.collectionName
    }


    // MARK: - NSCopy aka CopyingProtocol

    /// Provides an unregistered copy (the instance is not held by the dataPoint)
    ///
    /// - Parameter zone: the zone
    /// - Returns: the copy
    override open func copy(with zone: NSZone? = nil) -> Any {
        guard let data = try? JSON.encoder.encode(self) else {
            return ObjectError.message(message: "Encoding issue on copy of: \(FilePath.typeName) \(self.uid)")
        }
        guard let copy = try? JSON.decoder.decode(type(of:self), from: data) else {
            return ObjectError.message(message: "Decoding issue on copy of: \(FilePath.typeName) \(self.uid)")
        }
        return copy
    }
}



#if os(macOS) && USE_COCOA_BINDINGS

// You Can use Dynamic Override to support Cocoa Bindings
// This class can be used in a CollectionOf<T>

@objc open class DynamicFilePath:CommonFilePath{

    @objc override dynamic open var  relativePath : String{
        set{ super.relativePath = newValue }
        get{ return super.relativePath }
    }
}

#endif
