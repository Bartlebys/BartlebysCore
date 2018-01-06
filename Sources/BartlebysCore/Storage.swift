//
//  Storage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 24/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol StorageProgressDelegate{
    
    var identifier:String { get }
    
    func onProgress(_ fileName:String,_ success:Bool,_ message:String?, _ progress:Progress)->()
}


/// The storage layer
public final class Storage{

    /// If set to true the Storage is volatile
    /// It means it persist in memory only
    /// The FileStorage storage methods are ignored at runtime
    fileprivate var _volatile:Bool = false


    /// If you call once this method the datapoint will not persist out of the memory anymore
    /// You cannot turn back _volatile to false
    /// This mode allows to create temporary in Memory DataPoint to be processed and merged in persistent dataPoints
    public func becomeVolatile(){
        self._volatile = true
    }

    public let collectionExtension: String = ".data"
    
    /// You can / should register progress observers.
    /// to monitor the storage load and save.
    fileprivate var _observers=[StorageProgressDelegate]()
    
    // We use a static shared serial queue for all our operation
    fileprivate static var _sharedQueue:DispatchQueue = DispatchQueue(label: "org.bartlebys.collectionsQueue")
    
    // A unique file manager used exclusively on the shared queue
    fileprivate static var _fileManager = FileManager()
    
    fileprivate var _progress = Progress()
    
    public func addProgressObserver(observer:StorageProgressDelegate){
        self._observers.append(observer)
    }
    
    public func removeProgressObserver(observer:StorageProgressDelegate){
        if let idx = self._observers.index(where:{ $0.identifier == observer.identifier }) {
            self._observers.remove(at: idx)
        }
    }
    
    /// The base url of the storage (can be reset if necessary)
    public var baseUrl:URL = Paths.baseDirectoryURL
    
}

// MARK: - FileStorage

extension Storage: FileStorage{
    
    /// Loads asynchronously a collection from its file
    /// and insert the elements
    ///
    /// - Parameter proxy: the collection proxy
    public func load<T>(on proxy:CollectionOf<T>){
        guard let dataPoint = proxy.dataPoint else {
            return
        }

        guard self._volatile == false else{
            DispatchQueue.main.async {
                for observer in self._observers{
                    observer.onProgress(proxy.fileName, false, nil, self._progress)
                }
            }
            return
        }

        self._progress.totalUnitCount += 1
        let workItem = DispatchWorkItem.init(qos:.utility, flags:.inheritQoS) {
            
            do {
                let url = self.getURL(of: proxy)
                if Storage._fileManager.fileExists(atPath: url.path) {
                    let data = try Data(contentsOf: url)
                    let collection = try dataPoint.coder.decode(CollectionOf<T>.self, from: data)
                    DispatchQueue.main.async {
                        proxy.append(contentsOf: collection)
                    }
                }
                
                // The collection has been registered.
                DispatchQueue.main.async {
                    self._progress.completedUnitCount += 1
                    for observer in self._observers{
                        observer.onProgress(proxy.fileName, true, nil, self._progress)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    for observer in self._observers{
                        observer.onProgress(proxy.fileName, false, "\(error)", self._progress)
                    }
                }
            }
        }
        Storage._sharedQueue.async(execute: workItem)
    }
    
    
    
    
    /// Saves asynchronously the collection to a file on a separate queue
    ///
    /// - Parameters:
    ///   - collection: the collection reference
    ///   - dataPoint: the holding dataPoint
    public func saveCollection<T>(collection:CollectionOf<T>, using dataPoint:DataPoint){

        guard self._volatile == false else{
            DispatchQueue.main.async {
                for observer in self._observers{
                    observer.onProgress(collection.fileName, false, nil, self._progress)
                }
            }
            return
        }

        self._progress.totalUnitCount += 1
        let workItem = DispatchWorkItem.init(qos:.utility, flags:.inheritQoS) {
            
            do {
                let directoryURL = self.baseUrl.appendingPathComponent(collection.relativeFolderPath)
                let url = self.getURL(of: collection)
                
                var isDirectory: ObjCBool = true
                if !Storage._fileManager.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
                    try Storage._fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                let data = try dataPoint.coder.encode(collection)
                try data.write(to: url)
                collection.hasChanged = false
                
                DispatchQueue.main.async {
                    self._progress.completedUnitCount += 1
                    for observer in self._observers{
                        observer.onProgress(collection.d_collectionName, true, nil, self._progress)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    for observer in self._observers{
                        observer.onProgress(collection.fileName, false, "\(error)", self._progress)
                    }
                }
            }
        }
        Storage._sharedQueue.async(execute: workItem)
    }
    
    
    
    /// Erases the file(s) of the collection if there is one
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    /// That's why it is synchronous.
    ///
    /// - Parameter collection: the collection
    public func eraseFiles<T>(of collection:CollectionOf<T>){
        guard self._volatile == false else{
            return
        }
        let workItem = DispatchWorkItem.init(qos:.utility, flags:.inheritQoS) {
            do{
                let url = self.getURL(of: collection)
                if Storage._fileManager.fileExists(atPath: url.path) {
                    try Storage._fileManager.removeItem(at: url)
                }
            }catch{
                Logger.log("\(error)",category: .critical)
            }
        }
        Storage._sharedQueue.sync(execute: workItem)
    }
    
    /// Returns the URL of the collection file
    ///
    /// - Parameter collection: the collection
    /// - Returns: the collection file URL
    public func getURL<T>(of collection:CollectionOf<T>) -> URL {
        return self.baseUrl.appendingPathComponent(collection.relativeFolderPath).appendingPathComponent(collection.fileName + self.collectionExtension)
        
    }
    
}
