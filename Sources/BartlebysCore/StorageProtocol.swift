//
//  FileStorage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 25/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol StorageProtocol {

    // The storage concrete coder
    var coder:ConcreteCoder { get set }

    /// Adds a progress observer
    ///
    /// - Parameter observer: the observer
    func addProgressObserver(observer:StorageProgressDelegate)

    /// Removes the progress observer
    ///
    /// - Parameter observer: the observer
    func removeProgressObserver(observer:StorageProgressDelegate)


    /// If you call once this method the datapoint will not persist out of the memory anymore
    /// You cannot turn back _volatile to false
    /// This mode allows to create temporary in Memory DataPoint to be processed and merged in persistent dataPoints
    func becomeVolatile()

    // MARK: - Asynchronous (on an serial queue)

    /// Loads asynchronously a collection from its file
    /// and insert the elements in the collection proxy
    ///
    /// - Parameter proxy: the collection proxy
    func loadCollection<T>(on proxy:CollectionOf<T>)

    /// Saves asynchronously the collection to a file on a separate queue
    ///
    /// - Parameters:
    ///   - collection: the collection reference
    func saveCollection<T>(_ collection:CollectionOf<T>)

    // MARK: - Synchronous

    /// Loads a codable in the data point container Synchronously
    /// Should normally not be used on registered Collections.
    /// This method does not relay tasks progression
    ///
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the relative folder path
    /// - Returns: the instance
    func loadSync<T:Codable & Initializable >(fileName:String,relativeFolderPath:String)throws->T

    /// Save synchronously an Encodable & FilePersitent
    ///
    /// - Parameters:
    ///   - element: the element to save
    /// - Throws: throws encoding and file IO errors
    func saveSync<T:Codable>(element:T,fileName:String,relativeFolderPath:String)throws

}

