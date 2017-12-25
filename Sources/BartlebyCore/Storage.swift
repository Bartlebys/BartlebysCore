//
//  Storage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 24/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public final class Storage{

    // The Progress closure
    public typealias OnProgress = (_ fileName:String,_ success:Bool,_ message:String?, _ progress:Progress)->()

    /// You can / should register progress observers.
    /// to monitor the storage load and save.
    public var observer:OnProgress?

    // We use a static shared serial queue for all our operation
    fileprivate static var _sharedQueue:DispatchQueue = DispatchQueue(label: "org.bartlebys.collectionsQueue")

    // A unique file manager used exclusively on the shared queue
    fileprivate static var _fileManager = FileManager()

    fileprivate var _progress = Progress()

    public func setUpObserver(_ newObserver:@escaping OnProgress){
        self.observer = newObserver
    }

}

// MARK: - FileStorage

extension Storage: FileStorage{



    /// Loads asynchronously a collection from its file
    /// and insert the elements
    ///
    /// - Parameter proxy: the collection proxy
    public func load<T>(on proxy:ObjectCollection<T>){
        guard let dataPoint = proxy.dataPoint else {
            return
        }
        self._progress.totalUnitCount += 1
        let workItem = DispatchWorkItem.init(qos:.utility, flags:.inheritQoS) {

            do{
                let url = try Paths.directoryURL(relativeFolderPath: proxy.relativeFolderPath).appendingPathComponent(proxy.fileName + ".data")
                if Storage._fileManager.fileExists(atPath: url.path) {
                    let data = try Data(contentsOf: url)
                    let collection = try dataPoint.coder.decode(ObjectCollection<T>.self, from: data)
                    for item in collection{
                        proxy.upsert(item)
                    }
                }
                
                // The collection has been registered.
                DispatchQueue.main.async(execute: {
                    self._progress.completedUnitCount += 1
                    self.observer?(proxy.fileName, true, nil, self._progress)

                })
            }catch{
                DispatchQueue.main.async(execute: {
                    self.observer?(proxy.fileName, false, "\(error)", self._progress)
                })
            }
        }
        Storage._sharedQueue.async(execute: workItem)
    }


    

    /// Saves asynchronously the collection to a file on a separate queue
    ///
    /// - Parameters:
    ///   - collection: the collection reference
    ///   - fileName: the filename
    ///   - relativeFolderPath: the relative folder path
    ///   - dataPoint: the holding dataPoint
    public func saveCollectionToFile<T>(collection:ObjectCollection<T>,fileName: String, relativeFolderPath: String, using dataPoint:DataPoint){
        self._progress.totalUnitCount += 1
        let workItem = DispatchWorkItem.init(qos:.utility, flags:.inheritQoS) {

            do{
                collection.fileName = fileName
                let directoryURL = try Paths.directoryURL(relativeFolderPath: relativeFolderPath)
                let url = directoryURL.appendingPathComponent(fileName + ".data")

                var isDirectory: ObjCBool = true
                if !Storage._fileManager.fileExists(atPath: directoryURL.absoluteString, isDirectory: &isDirectory) {
                    try Storage._fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                }

                let data = try dataPoint.coder.encode(collection)
                try data.write(to: url)
                collection.hasChanged = false

                DispatchQueue.main.async(execute: {
                    self._progress.completedUnitCount += 1
                    self.observer?(collection.d_collectionName, true, nil, self._progress)
                })
            }catch{
                DispatchQueue.main.async(execute: {
                    self.observer?(fileName, false, "\(error)", self._progress)
                })
            }
        }
        Storage._sharedQueue.async(execute: workItem)
    }

}
