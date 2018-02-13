//
//  FiletPath+Absolute.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 13/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

enum FilePathError:Error {
    case undefinedDataPoint
}

extension FilePath{


    /// Computes an absolute URL according to the App and Datapoint Context.
    ///
    /// - Returns: the file URL
    /// - Throws: Paths issues
    public func absoluteFileURL() throws -> URL {
        guard let dataPoint = self.dataPoint else{
            throw FilePathError.undefinedDataPoint
        }
        return try Paths.directoryURL(relativeFolderPath:dataPoint.sessionIdentifier+"/"+self.relativePath)
    }


    /// Computes an absolute Path according to the App and Datapoint Context.
    ///
    /// - Returns: the filePath
    /// - Throws: Paths issues
    public func absoluteFilePath() throws -> String{
        return try self.absoluteFileURL().path
    }


    /// The convenience initializer
    ///
    /// - Parameters:
    ///   - relativePath: the file relative path
    ///   - dataPoint: the referent dataPoint
    public convenience init(relativePath:String,dataPoint:DataPoint){
        self.init()
        self.dataPoint = dataPoint
        self.relativePath = relativePath
    }

}
