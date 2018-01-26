//
//  CollectionOf.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 04/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation
import Dispatch

#if USE_BTREE
#if !USE_EMBEDDED_MODULES
   import BTree
#endif
   fileprivate typealias _ContainerType = List
#else
   fileprivate typealias _ContainerType = Array
#endif

public enum CollectionOfError:Error {
   case collectionIsNotRegistred
   case typeMissMatch
}

protocol ChangesFlag {
   var hasChanged: Bool { get }
   func didChange()
   func changesHasBeenSaved()
}



open class CollectionOf<T> : Collection, Sequence,IndistinctCollection, Codable, Selection, FileSavable, ChangesFlag where T :  Codable & Collectable {


   // MARK: -

   // @todo waiting for [SE-0143](https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md)
   fileprivate var _items: _ContainerType<T> = _ContainerType<T>()

   // We expose the collection type
   public var collectedType:T.Type { return T.self }

   // The dataPoint is set on Registration
   public var dataPoint:DataPoint?

   // If set to true the collection will be saved on the next save operations
   // ChangesFlag protocol
   public fileprivate(set) var hasChanged: Bool = false
   public func didChange() { self.hasChanged = true }
   public func changesHasBeenSaved() { self.hasChanged = false }

   // Loading flag
   public fileprivate(set) var isLoading: Bool = false
   public func startLoading() { self.isLoading = true }
   public func didLoad() { self.isLoading = false }

   // Saving flag
   public fileprivate(set) var isSaving: Bool = false
   public func startSaving() { self.isLoading = true }
   public func didSave() { self.isLoading = false }

   // You must setup a relativeFolderPath
   public lazy var relativeFolderPath: String = Default.NO_PATH

   // You can define a specific File name
   public var fileName:String = Default.NO_NAME

   public var name:String { return self.fileName }

   // MARK: - Initializer

   /// The designated proxy initializer
   ///
   /// - Parameters:
   ///   - named: the name of the collection is also its fileName
   ///   - relativePath: a relative path to be able to group/classify collections.
   public required init(named name:String = T.collectionName, relativePath:String = DataPoint.RelativePaths.forCollections.rawValue ){
         self.fileName = name
         self.relativeFolderPath = relativePath
   }


   /// Used to access to call operations
   /// Returns the call operation if revelent
   public var dynamicCallOperations:[CallOperationProtocol]? {
      return self._items as? [CallOperationProtocol]
   }


   // MARK: - Functional Programing layer support

   public var startIndex: Int { return self._items.startIndex }

   public var endIndex: Int { return self._items.endIndex }

   public func index(after i: Int) -> Int {
      return self._items.index(after: i)
   }

   public func index(where predicate: (T) throws -> Bool) rethrows -> Int? {
      return try self._items.index(where: predicate)
   }

   open subscript(index: Int) -> T {
      get {
         return self._items[index]
      }
      set(newValue) {
         self._items[index] = newValue
         self.hasChanged = true
         self.reference(newValue)
      }
   }


   @discardableResult public func remove(at index: Int) -> T {
      self.hasChanged = true
      return self._items.remove(at: index)
   }

   public func append(_ newElement: T) {
      self.hasChanged = true
      self._items.append(newElement)
      self.reference(newElement)
   }

   public func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
      self.hasChanged = true
      for item in newElements {
         self.append(item)
      }
   }

   public func filter(_ isIncluded: (T) throws -> Bool) rethrows -> [T] {
      return try self._items.filter(isIncluded)
   }

   public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
      return try self._items.map(transform)
   }

   public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, T) throws -> Result) rethrows -> Result {
      return try self._items.reduce(initialResult, nextPartialResult)
   }

   public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, T) throws -> ()) rethrows -> Result {
      return try self._items.reduce(into: initialResult, updateAccumulatingResult)
   }

   public func flatMap(_ transform: (T) throws -> String?) rethrows -> [String] {
      return try self._items.flatMap(transform)
   }

   public func flatMap<SegmentOfResult>(_ transform: (T) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence {
      return try self._items.flatMap(transform)
   }

   public func flatMap<ElementOfResult>(_ transform: (T) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
      return try self._items.flatMap(transform)
   }

   public func contains(where predicate: (T) throws -> Bool) rethrows -> Bool {
      return try self._items.contains(where: predicate)
   }

   public var first: Element? { return self._items.first }

   public var last: Element? { return self._items.last }

   public var count: Int { return self._items.count }

   public func removeAll(){
      self._items.removeAll()
   }

   // MARK: - Extended behaviour

   /// Appends or update the element
   ///
   /// - Parameter element: the element to be upserted
   public func upsert(_ element: T) {
      self.hasChanged = true
      // We first determine if there is an element by using the dataPoint registry
      // It is faster than determining the index.
      if let item = self.dataPoint?.registredOpaqueInstanceByUID(element.UID) as? T {
         // We compute its possiuble 
         if let idx = self._items.index(where: {$0.UID == element.UID }){
            self[idx] = item
            self.reference(element)
         }else{
            self.append(element)
         }
      } else {
         self.append(element)
      }
   }

   /// Merge the provided collection
   ///
   /// - Parameter collection: a collection
   public func merge(with collection: CollectionOf<T>) {
      for item in collection {
         self.upsert(item)
      }
   }
   
   // MARK: - IndistinctCollection

   /// References the element into its collection and the dataPoint registry
   ///
   /// - Parameter element: the element
   public func reference<T:  Codable & Collectable >(_ item:T){

      // We reference the collection
      item.setCollection(self)

      guard let dataPoint = self.dataPoint else{
         Logger.log("Undefined Datapoint", category:.critical)
         return
      }

      // Reference the datapoint
      item.setDataPoint(dataPoint)

      // And register globally the element
      dataPoint.register(item)

      // Deferred ownership
      if let item = item as? Model{
         // Re-build the own relation.
         item.ownedBy.forEach({ (ownerUID) in
            if let o = dataPoint.registredModelByUID(ownerUID){
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


   /// Removes the item from the collection
   ///
   /// - Parameter item: the item
   open func removeItem<C:Codable & Collectable>(_ item: C)throws->(){
      guard let castedItem = item as? T else{
         throw ErasingError.typeMissMatch
      }
      if let idx = self._items.index(where:{ return $0.id == castedItem.id }){
         self._items.remove(at: idx)
      }
   }

   // MARK: - IndistinctCollection.UniversalType

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


   // MARK: - Views

   /// Returns an array of Any view by reference
   /// Can be Used by Array Controllers in Cocoa bindings
   public var unTypedArrayView:[Any] {
      #if USE_BTREE
         return list.arrayView as! [Any]
      #else
         return self._items as [Any]
      #endif
   }

   /// Returns an array view by reference
   public var arrayView:[T]{
      #if USE_BTREE
          return list.arrayView as! [T]
      #else
         return self._items
      #endif
   }


   /// Returns a set with all the collected elements
   ///
   /// - Returns: the extracted set.
   public func setView() -> Set<T>{
      var set = Set<T>()
      for item in self._items{
         set.insert(item)
      }
      return set
   }


   // MARK: - Codable

   public enum CollectionCodingKeys: String, CodingKey {
      case items
      case fileName
      case relativeFolderPath
   }

   required public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CollectionCodingKeys.self)
      self._items = try values.decode(_ContainerType<T>.self, forKey:.items)
      self.fileName =  try values.decode(String.self, forKey:.fileName)
      self.relativeFolderPath = try values.decode(String.self,forKey:.relativeFolderPath)
   }

   open func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CollectionCodingKeys.self)
      try container.encode(self._items, forKey:.items)
      try container.encode(self.fileName, forKey:.fileName)
      try container.encode(self.relativeFolderPath, forKey: .relativeFolderPath)
   }


   // MARK: - FileSavable

   /// Saves to a given file named 'fileName'
   /// Into a dedicated folder named relativeFolderPath
   /// - Parameters:
   /// - Throws: throws errors on Coding
   public func saveToFile() throws {
      if self.hasChanged {
         guard let dataPoint = self.dataPoint else {
            throw CollectionOfError.collectionIsNotRegistred
         }
         try dataPoint.storage.saveCollection(self)
      }
   }


   // MARK: - Selection Support

   fileprivate let _selectedUIDSKeys="selected\(T.collectionName)UIDSKeys"

   // Recovers the selectedUIDS
   fileprivate var _selectedUIDs:[UID]{
      set{
         syncOnMain {
            do{
               try self.dataPoint?.storeInKVS(newValue, identifiedBy: self._selectedUIDSKeys)
            }catch{
               Logger.log("\(error)",category:.critical)
            }
         }
      }
      get{
         return syncOnMainAndReturn{ () -> [UID] in
            guard let dataPoint = self.dataPoint else {
               return [UID]()
            }
            if let UIDs:[UID] = try? dataPoint.getFromKVS(key:self._selectedUIDSKeys){
               return UIDs
            }
            return [UID]()
         }
      }
   }


   public var selectedItems:[T]?{
      get{
         return syncOnMainAndReturn { () -> [T]? in
            do{
               if let instances: [T] =  try self.dataPoint?.registredObjectsByUIDs(self._selectedUIDs){
                  return instances
               }
            }catch{
               // Silent catch
            }
            return nil
         }
      }
      set{
         syncOnMain {
            self._selectedUIDs = newValue?.map{$0.UID} ?? [UID]()
            Notify<T>.postSelectionChanged()
         }
      }
   }

   // A facility to access to the first selected item
   public var firstSelectedItem:T? {
      return syncOnMainAndReturn{ () -> T? in
         return self.selectedItems?.first
      }
   }

}
