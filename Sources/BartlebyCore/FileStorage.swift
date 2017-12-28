//
//  FileStorage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 25/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol FileStorage {

    /// Loads asynchronously a collection from its file
    /// and insert the elements in the collection proxy
    ///
    /// - Parameter proxy: the collection proxy
    func load<T>(on proxy:CollectionOf<T>)

    /// Saves the collection to a file on a separate queue
    ///
    /// - Parameters:
    ///   - collection: the collection reference
    ///   - fileName: the filename
    ///   - relativeFolderPath: the relative folder path
    ///   - dataPoint: the holding dataPoint
    func saveCollectionToFile<T>(collection:CollectionOf<T>,fileName: String, relativeFolderPath: String, using dataPoint:DataPoint)

}
