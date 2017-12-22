//
//  PersistentCollection.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 09/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol PersistentCollection {


    /// Loads from a file
    /// Creates the a new persistent instance if there is no file.
    /// Registers the collection 
    ///
    /// - Parameters:
    ///   - type: the Type of the FilePersistent instance
    ///   - fileName: the filename to use
    ///   - relativeFolderPath: the session identifier
    ///   - dataPoint: the dataPoint
    /// - Returns: a FilePersistent instance
    /// - Throws: throws errors on decoding
    static func createOrLoadFromFile<T:Codable & Tolerent>(type: T.Type, fileName: String, relativeFolderPath: String, using dataPoint:DataPoint) throws -> ObjectCollection<T>


    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the file relative folder path
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    func saveToFile(fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws
}
