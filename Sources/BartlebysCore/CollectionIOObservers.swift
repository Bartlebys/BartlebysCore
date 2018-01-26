//
//  CollectionIOObserver.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 26/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

// MARK: - The base BaseCollectionObserver

/// A base class the handle the storage Progress delegations.
public class BaseCollectionIOObserver:CollectionProgressObserver{

    // This identifier is used to distinguish the Observers
    public let identifier: UID = Utilities.createUID()

    // The referent dataPoint
    public let dataPoint:DataPoint

    // The initializer
    init(dataPoint:DataPoint) {
        self.dataPoint = dataPoint
    }

    /// The Progress method
    ///
    /// - Parameters:
    ///   - fileName: the filename
    ///   - success: is it a success?
    ///   - message: a contextual messsage
    ///   - progress: the progress object
    open func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {}
}

// MARK: - AutoRemovableStorageProgressHandler

// A Storage progress that uses an handler
public final class AutoRemovableStorageProgressHandler:BaseCollectionIOObserver{

    public typealias StorageProgress = (_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress)->()

    // The handler to handle the progress
    public var handler:StorageProgress

    /// An initializer with the dataPoint & the Handler
    ///
    /// - Parameters:
    ///   - dataPoint: the dataPoint reference
    ///   - handler: the handler to use
    init(dataPoint: DataPoint,handler:@escaping StorageProgress) {
        self.handler = handler
        super.init(dataPoint: dataPoint)
    }

    /// The Progress method
    ///
    /// - Parameters:
    ///   - fileName: the filename
    ///   - success: is it a success?
    ///   - message: a contextual messsage
    ///   - progress: the progress object
    override open func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
        self.handler(fileName, success, message, progress)
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
    }
}


// MARK: - AutoRemovableSavingDelegate

// A SavingDelegate that call the DataPoint delegate
internal final class AutoRemovableSavingDelegate:BaseCollectionIOObserver{


    // The initializer
    public override init(dataPoint:DataPoint) {
        super.init(dataPoint: dataPoint)
    }

    /// This Progress method calls the dataPoint delegate method
    ///     - collectionDidSaveSuccessFully() or collectionDidFailToSave(:)
    ///     - This observer is auto removed on completion
    /// - Parameters:
    ///   - fileName: the filename
    ///   - success: is it a success?
    ///   - message: a contextual messsage
    ///   - progress: the progress object
    override open func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
        if !success{
            self.dataPoint.collectionsDidFailToSave(dataPoint: self.dataPoint, message:message ?? "Failure when saving \(fileName)")
        }else if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.collectionsDidSaveSuccessFully(dataPoint: self.dataPoint)
        }
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
    }
}

// MARK: - AutoRemovableLoadingDelegate

// A LoadingDelegate that call the DataPoint delegate
internal final class AutoRemovableLoadingDelegate:BaseCollectionIOObserver{


    // The initializer
    public override init(dataPoint:DataPoint) {
        super.init(dataPoint: dataPoint)
    }


    /// This Progress method calls the dataPoint delegate method
    ///     - collectionDidSaveSuccessFully() or collectionDidFailToSave(:)
    ///     - This observer is auto removed on completion
    /// - Parameters:
    ///   - fileName: the filename
    ///   - success: is it a success?
    ///   - message: a contextual messsage
    ///   - progress: the progress object
    override public func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
        if !success{
            self.dataPoint.collectionsDidFailToLoad(dataPoint: self.dataPoint, message: message ?? "Failure when loading \(fileName)")
        }else if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.collectionsDidLoadSuccessFully(dataPoint: self.dataPoint)
        }
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
    }
}
