//
//  DataPoint+Helpers.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 13/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


extension DataPoint{


    /// Removes the registred instances from the registry
    ///
    /// - Parameter instance: the instance
    public func unRegister<T:  Codable & Collectable >(_ instances: [T]) {
        for instance in instances{
            self.unRegister(instance)
        }
    }

    // MARK: - Model level

    /// Returns a Model by its UID
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectable>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredModelByUID(_ UID: UID)-> Model? {
        return try? self.registredObjectByUID(UID)
    }

    /// Returns a collection of Model by UIDs
    /// Those instance are not casted.
    /// You should most of the time use : `registredObjectByUID<T: Collectable>(_ UID: String) throws-> T`
    /// - parameter UID:
    /// - returns: the instance
    public func registredModelByUIDs(_ UIDs: [UID])-> [Model]? {
        return try? self.registredObjectsByUIDs(UIDs)
    }


    /// Removes the registered item by its UID
    ///
    /// - Parameter uid: the UID
    /// - Returns: the item if found.
    public func removeRegistredModelByUID(_ uid:UID)->Model?{
        if let instance = self.registredModelByUID(uid){
            let collectionName = instance.d_collectionName
            if let collection = self.collectionNamed(collectionName){
                do{
                    let _ = try collection.removeItem(instance)
                }catch{
                    Logger.log(error, category: .critical)
                }
            }
            return instance
        }
        return nil
    }




    /// A Debug method that outputs a description of the datapoint files.
    ///
    /// - Returns: a lisible description
    public func filesDescription()->String{
        var description = "\n## Files Snapshot ##\nDatapoint.identifier: \(self.identifier)"
        if let fileStorage = self.storage as? FileStorage{
            let baseUrl = fileStorage.baseUrl
            description += "\n\(baseUrl.lastPathComponent)/"
            self._scanFolder(url: baseUrl, level:1, description: &description)
        }
        description += "\n"
        return description
    }

    fileprivate func _scanFolder(url:URL,level:Int, description: inout String, limit : Int = 50){
        do{
            let content = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            let sortedContent = content.sorted(by: { (u1, u2) -> Bool in
                return u1.lastPathComponent.compare(u2.lastPathComponent) == ComparisonResult.orderedAscending
            })
            let size = try FileManager.default.sizeOfFolder(at: url.path)
            description += " \(content.count) file\(content.count > 1 ? "s" : "") \(size.stringFileSize)"
            let indentation = String.init(repeating: "\t", count: level)
            var counter = 0
            for file in sortedContent{
                if counter < limit{
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) {
                        if isDirectory.boolValue == true{
                            description += "\n\(indentation)\(file.lastPathComponent)/"
                            self._scanFolder(url: file,level: level + 1, description: &description)
                        }else{
                            description += "\n\(indentation)\(file.lastPathComponent)"
                        }
                    }
                }else if counter == limit{
                     description += "\n\(indentation)..."
                }
                counter += 1
            }
        }catch{
            description += "\n\(error)"
        }
    }

}
