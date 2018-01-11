//
//  FileOperationError.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 11/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

enum FileOperationError : Error {
    case errorOn(filePath: FilePath, error: Error)
}
