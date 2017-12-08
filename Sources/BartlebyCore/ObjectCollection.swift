//
//  ManagedModelsCollection.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

open class ObjectCollection<T> : Codable where T : Codable & Collectible {
    
    public var items: [T] = [T]()

    public var hasChanged:Bool = false

    public init() {
    }
    
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
    

    static func directoryPath(type: T.Type) throws -> NSString {
        #if os(iOS) && os(macOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let _url = urls.first {
                //@todo add sessional identifier
                return _url.absoluteString as NSString
            }
        #elseif os(Linux) // linux @todo
            
        #endif
        throw FileSystemError.fileDirectoryNotFound
    }
    
    public static func loadFromFile(type: T.Type,fileName:String) throws -> ObjectCollection<T> {
        let data = try Data(contentsOf: self._url(type: type,fileName:fileName))
        return try JSONDecoder().decode(ObjectCollection<T>.self, from: data)
    }
    
    public func saveToFile(fileName:String) throws {
        if self.hasChanged{
            let url = try ObjectCollection._url(type: T.self,fileName: fileName)
            let data = try JSONEncoder().encode(self)
            //@todo create folder if necessary
            try data.write(to: url)
            self.hasChanged = false
        }
    }


    fileprivate static func _url(type: T.Type,fileName:String) throws -> URL {
        let directoryPath = try ObjectCollection.directoryPath(type:type)
        let filePath = (directoryPath as NSString).appendingPathComponent(type.collectionName)
        return URL(fileURLWithPath: "\(filePath).data")
    }

    
}
