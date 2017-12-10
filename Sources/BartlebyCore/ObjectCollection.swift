//
//  ManagedModelsCollection.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


open class ObjectCollection<T> : Codable,UniversalType,Tolerent, FilePersistentCollection where T : Codable & Collectible & Tolerent {



    // MARK: - UniversalType

    public static var collectionName:String { return ObjectCollection._collectionName() }

    public var d_collectionName: String { return ObjectCollection._collectionName() }

    fileprivate static func _collectionName()->String{
        return T.collectionName
    }

    public static var typeName: String {
        get{
           return "ObjectCollection<\(T.typeName)>"
        }
        set{}
    }

    // MARK: - Tolerent

    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        // No implementation
    }


    // MARK: -

    public var items: [T] = [T]()

    public var hasChanged:Bool = false

    public init() {
    }
    // MARK: -

    // MARK: - Codable
    
    public enum CollectionCodingKeys: String, CodingKey {
        case items
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CollectionCodingKeys.self)
        self.items = try values.decode([T].self, forKey:.items)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CollectionCodingKeys.self)
        try container.encode(self.items, forKey:.items)
    }
    
    // MARK: - IO
    
    enum FileSystemError : Error {
        case fileDirectoryNotFound
    }


    // MARK - FilePersistentCollection

    /// Loads from a file
    /// Creates the persistent instance if there is no file.
    ///
    /// - Parameters:
    ///   - type: the Type of the FilePersistent instance
    ///   - fileName: the filename to use
    ///   - sessionIdentifier: the session identifier
    ///   - coder: the coder
    /// - Returns: a FilePersistent instance
    /// - Throws: throws errors on decoding
    public static func createOrLoadFromFile<T:Codable & Tolerent>(type: T.Type, fileName: String, sessionIdentifier: String, using coder:ConcreteCoder) throws -> ObjectCollection<T>{
        let url = try ObjectCollection._url(type: type, fileName:fileName, sessionIdentifier: sessionIdentifier)
        if FileManager.default.fileExists(atPath: url.absoluteString){
            let data = try Data(contentsOf: self._url(type: type, fileName:fileName, sessionIdentifier: sessionIdentifier))
            return try coder.decode(ObjectCollection<T>.self, from: data)
        }else{
            return  ObjectCollection<T>()
        }
    }


    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named sessionIdentifier
    /// - Parameters:
    ///   - fileName: the file name
    ///   - sessionIdentifier: the session identifier (used for the folder and the identification of the session)
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    public func saveToFile(fileName: String, sessionIdentifier: String, using coder:ConcreteCoder) throws{
        if self.hasChanged {
            let url = try ObjectCollection._url(type: T.self, fileName: fileName, sessionIdentifier: sessionIdentifier)
            let data = try coder.encode(self)
            try data.write(to: url)
            self.hasChanged = false
        }
    }


    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named sessionIdentifier
    /// - Parameters:
    ///   - fileName: the file name
    ///   - sessionIdentifier: the session identifier (used for the folder and the identification of the session)
    /// - Throws: throws errors on Coding
    fileprivate static func _url<T>(type: T.Type, fileName: String, sessionIdentifier: String) throws -> URL {
        let directoryURL = try ObjectCollection._directoryURL(type:type, sessionIdentifier: sessionIdentifier)
        var isDirectory: ObjCBool = true
        
        if !FileManager.default.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        return directoryURL.appendingPathComponent(fileName + ".data")
    }


    private static func _directoryURL<T>(type: T.Type, sessionIdentifier: String) throws -> URL {
        #if os(iOS) || os(macOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let _url = urls.first {
                return _url.appendingPathComponent(sessionIdentifier, isDirectory: true)
            }
        #elseif os(Linux) // linux @todo
            
        #endif
        throw FileSystemError.fileDirectoryNotFound
    }
}

