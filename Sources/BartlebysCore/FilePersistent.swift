//
//  FilePersistent.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 25/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol FilePersistent{

    // We define a file name
    var fileName:String { get }

    // We define the relative folder path
    var relativeFolderPath:String { get }


    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named
    /// - Parameters:
    /// - Throws: throws errors on Coding
    func saveToFile() throws

}
