//
//  DataPoint+BackGroundProcessing.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 20/04/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

/// Universal equivalent of iOS' UIBackgroundFetchResult
///
/// - newData: UIBackgroundFetchResultNewData
/// - noData: UIBackgroundFetchResultNoData
/// - failed: UIBackgroundFetchResultFailed
public enum BackGroundCallsResult{
    case newData
    case noData
    case failed
}

extension DataPoint{

    public func proceedToABunchOfBackGroundCalls(completionHandler: @escaping(BackGroundCallsResult)->()) -> () {
        // Place holder Always respond immediately .newData
        // @todo provide an incremental data point calls
        completionHandler(BackGroundCallsResult.newData)
    }
}
