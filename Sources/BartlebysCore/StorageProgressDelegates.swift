//
//  StorageProgressDelegates.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 26/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

// MARK: - The base ProgressDelegate

/// A base class the handle the storage Progress delegations.
open class ProgressDelegate:StorageProgressDelegate{

    // This identifier is used to distinguish the Observers
    public let identifier: String = Utilities.createUID()

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
open class AutoRemovableStorageProgressHandler:ProgressDelegate{

    public typealias  StorageProgress = (_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress)->()

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
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
        self.handler(fileName, success, message, progress)
    }
}


// MARK: - AutoRemovableSavingDelegate

// A SavingDelegate that call the DataPoint delegate
public class AutoRemovableSavingDelegate:ProgressDelegate{


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
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
        if !success{
            self.dataPoint.delegate.collectionDidFailToSave(message:message ?? "Failure when saving \(fileName)")
        }else if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.delegate.collectionDidSaveSuccessFully()
        }
    }
}

// MARK: - AutoRemovableLoadingDelegate

// A LoadingDelegate that call the DataPoint delegate
public class AutoRemovableLoadingDelegate:ProgressDelegate{


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
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
        if !success{
            self.dataPoint.delegate.collectionDidFailToLoad(message: message ?? "Failure when loading \(fileName)")
        }else if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.delegate.collectionDidLoadSuccessFully()
        }
    }
}
