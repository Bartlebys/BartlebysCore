//
//  CollectionOf.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation
import Dispatch
enum CollectionOfError:Error {
    case collectionIsNotRegistred
}


public final class CollectionOf<T> : Codable, UniversalType, Tolerent, Collection,ErasableContainer, Sequence, FilePersistent where T : Codable & Collectible & Tolerent {


    // MARK: -

    // Todo use a Btree storage.
    private var _storage: [T] = [T]()

    // We expose the collection type
    public var collectedType:T.Type { return T.self }

    // You must setup a relativeFolderPath
    public var relativeFolderPath: String

    // The dataPoint is set on Registration
    public var dataPoint:DataPoint?

    // If set to true the collection will be saved on the next save operations
    public var hasChanged: Bool = false

    // We can have several collection with the same type (e.g: some CallOperation)
    // so we we use also a file name to distiguish the collections.
    // Part of the FilePersistentCollection protocol
    public var fileName:String

    public var name:String { return self.fileName }

    // MARK: - UniversalType
    
    public static var collectionName:String { return CollectionOf._collectionName() }
    
    public var d_collectionName: String { return CollectionOf._collectionName() }
    
    fileprivate static func _collectionName()->String{
        return T.collectionName
    }

    public static var typeName: String {
        get {
            return "CollectionOf<\(T.typeName)>"
        }
        set {}
    }

    // MARK: - Initializer


    /// The designated initializer
    ///
    /// - Parameters:
    ///   - named: the name of the collection is also its fileName
    ///   - relativePath: a relative path to be able to group/classify collections.
    public required init(named:String, relativePath:String){
        self.fileName = named
        self.relativeFolderPath = relativePath
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
            self.hasChanged = true
            self.reference(newValue)
        }
    }

    /// References the element into the dataPoint registry
    ///
    /// - Parameter element: the element
    func reference<T: Codable & Collectible & Tolerent >(_ element:T){
        // We reference the collection
        element.setCollection(self)

        guard let dataPoint = self.dataPoint else{
            Logger.log("Undefined Datapoint", category: Logger.Categories.critical)
            return
        }

        // Reference the datapoint
        element.setDataPoint(dataPoint)
        
        // And register globally the element
        dataPoint.register(element)

        // Deferred ownership
        if let item = element as? ManagedModel{
            // Re-build the own relation.
            item.ownedBy.forEach({ (ownerUID) in
                if let o = dataPoint.registredManagedModelByUID(ownerUID){
                    if !o.owns.contains(item.UID){
                        o.owns.append(item.UID)
                    }
                }else{
                    // If the owner is not already available defer the homologous ownership registration.
                    dataPoint.appendToDeferredOwnershipsList(item, ownerUID: ownerUID)
                }
            })
        }
    }
    
    @discardableResult public func remove(at index: Int) -> T {
        self.hasChanged = true
        return self._storage.remove(at: index)
    }
    
    public func append(_ newElement: T) {
        self.hasChanged = true
        self._storage.append(newElement)
        self.reference(newElement)
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

    // MARK: - Accessors


    /// Returns all the stored element packaged in an Array
    public var all:Array<T> {
        return self._storage
    }


    // MARK: - Codable
    
    public enum CollectionCodingKeys: String, CodingKey {
        case items
        case fileName
        case relativeFolderPath
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CollectionCodingKeys.self)
        self._storage = try values.decode([T].self, forKey:.items)
        self.fileName =  try values.decode(String.self, forKey:.fileName)
        self.relativeFolderPath = try values.decode(String.self,forKey:.relativeFolderPath)
        for element in self._storage{
            self.reference(element)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CollectionCodingKeys.self)
        try container.encode(self._storage, forKey:.items)
        try container.encode(self.fileName, forKey:.fileName)
        try container.encode(self.relativeFolderPath, forKey: .relativeFolderPath)
    }
    
    
    // MARK: - Tolerent
    
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        // No implementation
    }

    // MARK: - FilePersistentCollection

    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named relativeFolderPath
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the session identifier (used for the folder and the identification of the session)
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    public func saveToFile(fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws {
        if self.hasChanged {
            guard let dataPoint = self.dataPoint else {
                throw CollectionOfError.collectionIsNotRegistred
            }
            dataPoint.storage.saveCollectionToFile(collection: self, fileName: fileName, relativeFolderPath: relativeFolderPath, using: dataPoint)
        }
    }


    // MARK: - ErasableContainer

    /// A remove function with type erasure to enable to performe ManagedModel+Erasure
    ///
    /// - Parameters:
    ///   - item: the item to erase
    ///   - commit: should we commit the erasure?
    public func remove(_ item: Any , commit:Bool)throws->(){
        guard let castedItem = item as? T else{
            throw ErasingError.typeMissMatch
        }
        if let idx = self._storage.index(where:{ return $0.id == castedItem.id }){
            self._storage.remove(at: idx)
        }
        // @todo commit
    }

}


