//
//  ManagedModelsCollection.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


open class ObjectCollection<T> : Codable, UniversalType, Tolerent, FilePersistentCollection, Collection, Sequence where T : Codable & Collectible & Tolerent {

    // MARK: -

    // We will try to add a Btree storage.
    // reference : https://github.com/objcio/OptimizingCollections

    private var _storage: [T] = [T]()

    public var hasChanged: Bool = false

    // MARK: - UniversalType
    
    public static var collectionName:String { return ObjectCollection._collectionName() }
    
    public var d_collectionName: String { return ObjectCollection._collectionName() }
    
    fileprivate static func _collectionName()->String{
        return T.collectionName
    }
    
    public static var typeName: String {
        get {
            return "ObjectCollection<\(T.typeName)>"
        }
        set {}
    }
    
    // MARK: -

    public init() {
    }
    
    // MARK: - Functional Programing Storage layer support
    
    public var startIndex: Int { return self._storage.startIndex }
    
    public var endIndex: Int { return self._storage.endIndex }
    
    public func index(after i: Int) -> Int {
        return self._storage.index(after: i)
    }
    
    public func index(where predicate: (T) throws -> Bool) rethrows -> Int? {
        return try self._storage.index(where: predicate)
    }
    
    public subscript(index: Int) -> T {
        get {
            return self._storage[index]
        }
        set(newValue) {
            self._storage[index] = newValue
            //            self._storage.insert(newValue, at: index)
            self.hasChanged = true
        }
    }
    
    @discardableResult public func remove(at index: Int) -> T {
        self.hasChanged = true
        return self._storage.remove(at: index)
    }
    
    public func append(_ newElement: T) {
        self.hasChanged = true
        self._storage.append(newElement)
    }
    
    public func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        self.hasChanged = true
        for item in newElements {
            self.append(item)
        }
    }
    
    public func filter(_ isIncluded: (T) throws -> Bool) rethrows -> [T] {
        return try self._storage.filter(isIncluded)
    }
    
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        return try self._storage.map(transform)
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, T) throws -> Result) rethrows -> Result {
        return try self._storage.reduce(initialResult, nextPartialResult)
    }
    
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, T) throws -> ()) rethrows -> Result {
        return try self._storage.reduce(into: initialResult, updateAccumulatingResult)
    }
    
    public func flatMap(_ transform: (T) throws -> String?) rethrows -> [String] {
        return try self._storage.flatMap(transform)
    }
    
    public func flatMap<SegmentOfResult>(_ transform: (T) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence {
        return try self._storage.flatMap(transform)
    }
    
    public func flatMap<ElementOfResult>(_ transform: (T) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        return try self._storage.flatMap(transform)
    }
    
    public func contains(where predicate: (T) throws -> Bool) rethrows -> Bool {
        return try self._storage.contains(where: predicate)
    }
    
    public var first: Element? { return self._storage.first }
    
    public var count: Int { return self._storage.count }
    
    // MARK: - Extended behaviour
    
    /// Appends or update the element
    ///
    /// - Parameter element: the element to be upserted
    public func upsert(_ element: T) {
        self.hasChanged = true
        
        if let idx = self.index(where: {$0.id == element.id}) {
            self[idx] = element
        } else {
            self._storage.append(element)
        }
        
    }
    
    // MARK: - Codable
    
    public enum CollectionCodingKeys: String, CodingKey {
        case items
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CollectionCodingKeys.self)
        self._storage = try values.decode([T].self, forKey:.items)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CollectionCodingKeys.self)
        try container.encode(self._storage, forKey:.items)
    }
    
    
    

    // MARK - FilePersistentCollection

    /// Loads from a file
    /// Creates the persistent instance if there is no file.
    ///
    /// - Parameters:
    ///   - type: the Type of the FilePersistent instance
    ///   - fileName: the filename to use
    ///   - relativeFolderPath: the session identifier
    ///   - coder: the coder
    /// - Returns: a FilePersistent instance
    /// - Throws: throws errors on decoding
    public static func createOrLoadFromFile<T:Codable & Tolerent>(type: T.Type, fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws -> ObjectCollection<T>{
        let url = try ObjectCollection._url(type: type, fileName:fileName, relativeFolderPath: relativeFolderPath)
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: self._url(type: type, fileName:fileName, relativeFolderPath: relativeFolderPath))
            let result = try coder.decode(ObjectCollection<T>.self, from: data)
            return result
        } else {
            return  ObjectCollection<T>()
        }
    }

    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named relativeFolderPath
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the session identifier (used for the folder and the identification of the session)
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    public func saveToFile(fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws {
        if self.hasChanged {
            let url = try ObjectCollection._url(type: T.self, fileName: fileName, relativeFolderPath: relativeFolderPath)
            let data = try coder.encode(self)
            try data.write(to: url)
            self.hasChanged = false
            
            let notificationName = NSNotification.Name.ObjectCollection.saveDidSucceed(fileName)
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }

    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named relativeFolderPath
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the session identifier (used for the folder and the identification of the session)
    /// - Throws: throws errors on Coding
    fileprivate static func _url<T>(type: T.Type, fileName: String, relativeFolderPath: String) throws -> URL {
        let directoryURL = try Paths.directoryURL(relativeFolderPath: relativeFolderPath)
        var isDirectory: ObjCBool = true
        
        if !FileManager.default.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        return directoryURL.appendingPathComponent(fileName + ".data")
    }

    // MARK: - Tolerent
    
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        // No implementation
    }
    
}

