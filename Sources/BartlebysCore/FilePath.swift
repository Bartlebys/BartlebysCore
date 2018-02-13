//
//  FileOperation.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 11/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class FilePath : Model, Payload, Result {
    
    public var relativePath: String = Default.NOT_SPECIFIED

    /// Computes an absolute URL according to the App and Datapoint Context.
    ///
    /// - Parameter dataPoint: the dataPoint
    /// - Returns: the file URL
    /// - Throws: Paths issues
    public func fileUrlFor(dataPoint: DataPoint) throws -> URL {
        return try Paths.directoryURL(relativeFolderPath:dataPoint.sessionIdentifier+"/"+self.relativePath)
    }

    public func absolutePath(dataPoint: DataPoint) throws -> String{
        return try self.fileUrlFor(dataPoint: dataPoint).path
    }

    
    public enum FilePathCodingKeys: String, CodingKey {
        case relativePath
    }
    
    required public init() {
        super.init()
    }

    required public init(relativePath: String) {
        super.init()
        self.relativePath = relativePath
    }
    
    public required init(from decoder: Decoder) throws{
        super.init()
        let values = try decoder.container(keyedBy: FilePathCodingKeys.self)
        self.id = try values.decode(String.self, forKey:.relativePath)

    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FilePathCodingKeys.self)
        try container.encode(self.relativePath, forKey:.relativePath)
    }

}
