//
//  FilePersistentCollection.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 25/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol FilePersistentCollection{

    // We define a file name
    var fileName:String { get }

    // We define the relative folder path
    var relativeFolderPath:String { get }

    // The collected Type
    var type:(Codable & Collectible & Tolerent).Type { get }

    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named
    /// - Parameters:
    ///   - fileName: the file name
    ///   - relativeFolderPath: the file relative folder path
    ///   - coder: the coder
    /// - Throws: throws errors on Coding
    func saveToFile(fileName: String, relativeFolderPath: String, using coder:ConcreteCoder) throws

}
