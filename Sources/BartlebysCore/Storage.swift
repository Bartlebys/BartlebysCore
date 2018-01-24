//
//  Storage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 24/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation
import Dispatch

public enum FileStorageError:Error {
    case undefinedDataPoint
    case notFound
}

public enum CollectionIOError<T:Collectable & Codable>:Error{
    case multipleLoadAttempts(collection: CollectionOf<T>)
    case multipleSaveAttempts(collection: CollectionOf<T>)
}

public protocol CollectionProgressObserver{
    
    var identifier:UID { get }
    
    func onProgress(_ fileName:String,_ success:Bool,_ message:String?, _ progress:Progress)->()
}


/// The storage layer
public final class Storage{

    /// The coder: encodes and decodes the Data
    public var coder: ConcreteCoder = JSONCoder()

    /// If set to true the Storage is volatile
    /// It means it persist in memory only
    /// The FileStorage storage methods are ignored at runtime
    public fileprivate(set) var isVolatile:Bool = false

    /// If you call once this method the datapoint will not persist out of the memory anymore
    /// You cannot turn back _volatile to false
    /// This mode allows to create temporary in Memory DataPoint to be processed and merged in persistent dataPoints
    public func becomeVolatile(){
        self.isVolatile = true
    }

    public let fileExtension: String = ".data"
    
    /// You can / should register progress observers.
    /// to monitor the storage load and save.
    fileprivate var _observers=[CollectionProgressObserver]()
    
    /// We use a serial queue for all our IO
    public fileprivate(set) var persistencyQueue:DispatchQueue = DispatchQueue(label: "org.bartlebys.collectionsQueue", qos: .utility, attributes: [])

    /// The observation queue (any progress message will be dispatched asynchronously on this queue)
    public var observationQueue:DispatchQueue = DispatchQueue.main

    /// This queue is used to integrate the loaded data.
    public var dataQueue:DispatchQueue = DispatchQueue.main

    // A unique file manager used exclusively on the persistencyQueue
    public fileprivate(set) var fileManager = FileManager()

    // The progress is incremented / decremented via DispatchQueue.main.async
    public fileprivate(set) var progress = Progress()

    fileprivate enum ProgressAction{
        case loadCollection
        case saveCollection
    }

    fileprivate func _incrementProgressTotalUnitCount(with action:ProgressAction){
        self.observationQueue.async {
            self.progress.totalUnitCount += 1
        }
    }

    public func addProgressObserver(observer:CollectionProgressObserver){
        guard self._observers.index(where:{ $0.identifier == observer.identifier }) == nil else{
            Logger.log("Attempt to a CollectionProgressObserver multiple times \(observer.identifier)", category: .warning)
            return
        }
        self._observers.append(observer)
    }
    
    public func removeProgressObserver(observer:CollectionProgressObserver){
        if let idx = self._observers.index(where:{ $0.identifier == observer.identifier }) {
            self._observers.remove(at: idx)
        }
    }
    
    /// The base url of the storage (can be reset if necessary)
    public var baseUrl:URL = Paths.baseDirectoryURL
    
}

// MARK: - FileStorageProtocol

extension Storage: FileStorageProtocol{


    // MARK: - Asynchronous (on an serial queue)
    
    /// Loads asynchronously a collection from its file
    /// and insert the elements
    ///
    /// - Parameter proxy: the collection proxy
    public func loadCollection<T>(on proxy:CollectionOf<T>)throws{

        if self.isVolatile == true {
            self._relayTaskCompletionToObservers(collection: proxy, success: true, error: nil)
            return
        }

        if proxy.isLoading{
            throw CollectionIOError.multipleLoadAttempts(collection: proxy)
        }

        proxy.startLoading()

        self._incrementProgressTotalUnitCount(with: ProgressAction.loadCollection)

        self.persistencyQueue.async{
            do {
                let url = self.getURL(of: proxy)
                if self.fileManager.fileExists(atPath: url.path) {
                    let data = try Data(contentsOf: url)
                    let collection = try self.coder.decode(CollectionOf<T>.self, from: data)
                    self.dataQueue.async {
                        proxy.append(contentsOf: collection)
                        proxy.didLoad()
                    }
                }
                // The collection has been saved.
                self._relayTaskCompletionToObservers(collection: proxy, success: true, error: nil)

            } catch {
                self._relayTaskCompletionToObservers(collection: proxy, success: false, error: error)
            }
        }
    }
    
    
    
    
    /// Saves asynchronously any FilePersistent & Encodable a separate queue
    ///
    /// - Parameters:
    ///   - collection: the collection reference
    public func saveCollection<T>(_ collection:CollectionOf<T>)throws{

        if self.isVolatile {
            self._relayTaskCompletionToObservers(collection: collection, success: true, error: nil)
            return
        }

        if collection.isSaving{
            throw CollectionIOError.multipleSaveAttempts(collection: collection)
        }

        collection.startSaving()

        self._incrementProgressTotalUnitCount(with:ProgressAction.saveCollection)
        self.persistencyQueue.async{
            do {
                let directoryURL = self.baseUrl.appendingPathComponent(collection.relativeFolderPath)
                let url = self.getURL(of: collection)

                var isDirectory: ObjCBool = true
                if !self.fileManager.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
                    try self.fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                }

                let data = try self.coder.encode(collection)
                try data.write(to: url)
                collection.changesHasBeenSaved()
                collection.didSave()

                // The collection has been saved.
                self._relayTaskCompletionToObservers(collection: collection, success: true, error: nil)

            } catch {
                self._relayTaskCompletionToObservers(collection: collection, success: false, error: error)
            }
        }
    }



    /// Relays to the observers and clean up the _progress
    ///
    /// - Parameters:
    ///   - action: the progres action
    ///   - fileName: the fileName
    ///   - success: the success state
    ///   - error: the associated error
    fileprivate func _relayTaskCompletionToObservers<T>(collection:CollectionOf<T>,success:Bool, error:Error?){
        self.observationQueue.async {
            self.progress.completedUnitCount += 1
            for observer in self._observers{
                if let error = error{
                    observer.onProgress(collection.fileName, success, "\(error)", self.progress)
                }else{
                    observer.onProgress(collection.fileName, success, nil, self.progress)
                }
            }
            // Reset if necessary the progress object
            if self.progress.completedUnitCount == self.progress.totalUnitCount {
                self.progress.completedUnitCount = 0
                self.progress.totalUnitCount = 0
            }
        }
    }


    // MARK: - Synchronous


    /// Loads a codable in the data point container Synchronously
    ///
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the relative folder path
    /// - Returns: the instance
    public func loadSync<T:Codable  >(fileName:String,relativeFolderPath:String)throws->T{
        if !self.isVolatile{
            let url = self.getURL(ofFile: fileName, within: relativeFolderPath)
            // We do not use the storage file manager.
            // That performs on an async utility queue
            if self.fileManager.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                return try self.coder.decode(T.self, from: data)
            }
        }
        throw FileStorageError.notFound
    }


    /// Save synchronously an Encodable & FilePersitent
    ///
    /// - Parameters:
    ///   - element: the element to save
    /// - Throws: throws encoding and file IO errors
    public func saveSync<T:Codable>(element:T,fileName:String,relativeFolderPath:String)throws{
        if !self.isVolatile  {
            let directoryURL = self.baseUrl.appendingPathComponent(relativeFolderPath)
            let url = self.getURL(ofFile: fileName, within: relativeFolderPath)

            var isDirectory: ObjCBool = true
            if !self.fileManager.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
                try self.fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            let data = try self.coder.encode(element)
            try data.write(to: url)
            (element as? ChangesFlag)?.changesHasBeenSaved()
        }
    }

    // MARK : -

    /// Returns the URL of a FilePersistent element
    ///
    /// - Parameter collection: the collection
    /// - Returns: the collection file URL
    public func getURL<T:FilePersistent>(of element:T) -> URL {
        return self.getURL(ofFile: element.fileName, within: element.relativeFolderPath)
    }



    /// Returns the URL
    ///
    /// - Parameters:
    ///   - named: the name without the extension
    ///   - relativeFolderPath: the relative folder path
    /// - Returns: the URL
    public func getURL(ofFile named:String,within relativeFolderPath:String) -> URL {
        return self.baseUrl.appendingPathComponent(relativeFolderPath).appendingPathComponent(named + self.fileExtension)
    }


    // MARK: - File Erasure

    /// Erases the file(s) of the collection if there is one
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    /// That's why it is synchronous.
    ///
    /// - Parameter collection: the collection
    public func eraseFilesOfCollection<T:FilePersistent>(of element:T){
        if self.isVolatile == true {
            return
        }
        self.persistencyQueue.sync{
            do{
                let url = self.getURL(of: element)
                if self.fileManager.fileExists(atPath: url.path) {
                    try self.fileManager.removeItem(at: url)
                }
            }catch{
                Logger.log("\(error)",category: .critical)
            }
        }
    }

    /// Erases all the files.
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    /// That's why it is synchronous.
    public func eraseFiles(){
        if self.isVolatile == true {
            return
        }
        self.persistencyQueue.sync{
            do{
                let url = self.baseUrl
                if self.fileManager.fileExists(atPath: url.path) {
                    try self.fileManager.removeItem(at: url)
                }
            }catch{
                Logger.log("\(error)",category: .critical)
            }
        }
    }

    /// Erases the file if there is one
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    ///
    /// - Parameter collection: the collection
    public func eraseFile(fileName:String,relativeFolderPath:String){
        do{
            let url = self.getURL(ofFile: fileName, within: relativeFolderPath)
            if self.fileManager.fileExists(atPath: url.path) {
                try self.fileManager.removeItem(at: url)
            }
        }catch{
            Logger.log("\(error)",category: .critical)
        }
    }


    
}
