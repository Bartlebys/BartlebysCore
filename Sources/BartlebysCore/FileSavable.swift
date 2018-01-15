//
//  FileSavable.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 15/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public protocol FileSavable:FilePersistent{

    /// Saves to a given file named 'fileName'
    /// Into a dedicated folder named
    /// - Parameters:
    /// - Throws: throws errors on Coding
    func saveToFile() throws

}
