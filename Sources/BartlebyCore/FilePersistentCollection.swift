//
//  FilePersistentCollection.swift
//  BartlebysCoreiOS
//
//  Created by Benoit Pereira da silva on 09/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol FilePersistentCollection {


    /// Loads from a file
    /// Creates the persistent instance if there is no file.
    ///
    /// - Parameters:
    ///   - type: the Type of the FilePersistent instance
    ///   - fileName: the filename to use
    ///   - relativeFolderPath: the file relative folder path
    ///   - coder: the coder
    /// - Returns: a FilePersistent instance
    /// - Throws: throws errors on decoding
    static func createOrLoadFromFile<T>(type: T.Type, fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws -> ObjectCollection<T>


    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the file relative folder path
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    func saveToFile(fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws
}
