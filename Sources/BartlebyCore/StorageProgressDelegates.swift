//
//  StorageProgressDelegates.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 26/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

// MARK : - The base ProgressDelegate


/// A base class the handle the storage Progress delegations.
open class ProgressDelegate:StorageProgressDelegate{

    public let identifier: String = Utilities.createUID()

    public let dataPoint:DataPoint

    init(dataPoint:DataPoint) {
        self.dataPoint = dataPoint
    }

    open func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
    }
}

// MARK : - StorageProgressHandler

// A Storage progress that uses an handler
open class StorageProgressHandler:ProgressDelegate{

    public typealias  StorageProgress = (_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress)->()

    public var handler:StorageProgress

    init(dataPoint: DataPoint,handler:@escaping StorageProgress) {
        self.handler = handler
        super.init(dataPoint: dataPoint)
    }

    override open func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
        self.handler(fileName, success, message, progress)
    }
}


// MARK : - SavingDelegate

// A SavingDelegate that call the DataPoint delegate
public class DataPointSavingDelegate:ProgressDelegate{

    override public func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
        if !success{
            self.dataPoint.delegate.collectionDidFailToSave(message: message ?? "Failure when saving \(fileName)")
        }else if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.delegate.collectionDifSaveSuccessFully()
        }
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
    }
}

// MARK : - LoadingDelegate

// A LoadingDelegate that call the DataPoint delegate
public class DataPointLoadingDelegate:ProgressDelegate{

    override public func onProgress(_ fileName: String, _ success: Bool, _ message: String?, _ progress: Progress) {
        if !success{
            self.dataPoint.delegate.collectionDidFailToLoad(message: message ?? "Failure when loading \(fileName)")
        }else if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.delegate.collectionDidLoadSuccessFully()

        }
        if progress.totalUnitCount == progress.completedUnitCount{
            self.dataPoint.storage.removeProgressObserver(observer: self)
        }
    }
}
