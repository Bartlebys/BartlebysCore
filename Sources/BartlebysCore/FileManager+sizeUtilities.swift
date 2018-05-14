//
//  FileManager+sizeUtilities.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 14/05/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public enum FileSizeUtilitiesError:Error {
    case invalid(attribute:FileAttributeKey)
}

public extension FileManager{


    /// Defines an invalidFileSize
    public static var invalidFileSize: Int64 { return -1 }


    /// Return the available free space (in the volume that contains the current home directory)
    public var systemFreeSpace: Int64{
        do{
            return try self.spaceInBytes(forPath: NSHomeDirectory(),fileAttributeKey: FileAttributeKey.systemFreeSize)
        }catch{
            return FileManager.invalidFileSize
        }
    }

     /// Return the total space (in the volume that contains the current home directory)
    public var systemTotalSpace: Int64{
        do{
            return try self.spaceInBytes(forPath: NSHomeDirectory(),fileAttributeKey: FileAttributeKey.systemSize)
        }catch{
            return FileManager.invalidFileSize
        }
    }

    /// Return the used space (in the volume that contains the current home directory)
    public var systemUsedSpace: Int64{
        return self.systemTotalSpace - self.systemFreeSpace
    }


    /// Returns the size of the content of a folder
    ///
    /// - Parameter path: the folder path
    /// - Returns: the cumulated size
    /// - Throws: ...
    public func sizeOfFolder(at path:String) throws -> Int64{
        var size:Int64 = 0
        let folderURL = URL(fileURLWithPath: path)
        let urls = try self.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: [])
        for url in urls{
            let attributes: [FileAttributeKey : Any] = try self.attributesOfItem(atPath: url.path)
            if let fileSize: Int64 = attributes[FileAttributeKey.size] as? Int64{
                size = size + fileSize
            }
        }
        return size
    }


    fileprivate func spaceInBytes(forPath:String,fileAttributeKey:FileAttributeKey = FileAttributeKey.size) throws -> Int64{
        let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: forPath)
        guard let space = (systemAttributes[fileAttributeKey] as? NSNumber)?.int64Value else{
            throw FileSizeUtilitiesError.invalid(attribute: fileAttributeKey)
        }
        return space
    }

}


//MARK: - Int64 String facility

public extension Int64{

    public var stringFileSize: String {
        return ByteCountFormatter.string(fromByteCount: self, countStyle:.file)
    }
}



