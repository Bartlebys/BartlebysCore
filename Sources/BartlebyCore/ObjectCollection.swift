//
//  ManagedModelsCollection.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


open class ObjectCollection<T> : Codable,UniversalType,FilePersistent where T : Codable & Collectible {


    public static var collectionName:String { return  T.collectionName }

    public var d_collectionName: String { return T.collectionName }

    public static var typeName: String {
        get{
            return "ObjectCollection<\(T.typeName)>"
        }
        set{}
    }

    public var items: [T] = [T]()

    public var collectionName:String { return T.collectionName }

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


    // MARK - FilePersistent

    public static func createOrLoadFromFile<T>(type: T.Type, fileName: String, sessionIdentifier: String) throws -> ObjectCollection<T> where T : Collectible & Codable{
        let url = try ObjectCollection._url(type: type, fileName:fileName, sessionIdentifier: sessionIdentifier)
        if FileManager.default.fileExists(atPath: url.absoluteString){
            let data = try Data(contentsOf: self._url(type: type, fileName:fileName, sessionIdentifier: sessionIdentifier))
            return try JSONDecoder().decode(ObjectCollection<T>.self, from: data)
        }else{
            return  ObjectCollection<T>()
        }
    }


    public func saveToFile(fileName: String, sessionIdentifier: String) throws {
        if self.hasChanged {
            let url = try ObjectCollection._url(type: T.self, fileName: fileName, sessionIdentifier: sessionIdentifier)
            let data = try JSONEncoder().encode(self)
            try data.write(to: url)
            self.hasChanged = false
        }
    }

    fileprivate static func _url<T:Collectible>(type: T.Type, fileName: String, sessionIdentifier: String) throws -> URL {
        let directoryURL = try ObjectCollection._directoryURL(type:type, sessionIdentifier: sessionIdentifier)
        var isDirectory: ObjCBool = true
        
        if !FileManager.default.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        return directoryURL.appendingPathComponent(type.collectionName + ".data")
    }

    private static func _directoryURL<T:Collectible>(type: T.Type, sessionIdentifier: String) throws -> URL {
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

