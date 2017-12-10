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
    ///   - sessionIdentifier: the session identifier
    ///   - coder: the coder
    /// - Returns: a FilePersistent instance
    /// - Throws: throws errors on decoding
    static func createOrLoadFromFile<T>(type: T.Type, fileName: String, sessionIdentifier: String, using coder:ConcreteCoder) throws -> ObjectCollection<T>


    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named sessionIdentifier
    /// - Parameters:
    ///   - fileName: the file name
    ///   - sessionIdentifier: the session identifier (used for the folder and the identification of the session)
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    func saveToFile(fileName: String, sessionIdentifier: String, using coder:ConcreteCoder) throws
}
