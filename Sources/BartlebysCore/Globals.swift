//
//  Globals.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 08/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

// Bartleby 1.0 for MongodB (can be set-up uses Model.ModelCodingKeys._id)
// In Most context Model.ModelCodingKeys.id is relevant.
public var MODELS_PRIMARY_KEY:Model.ModelCodingKeys = Model.ModelCodingKeys.id

// the explicit UID type used for expressivity
public typealias UID = String

// MARK: - Time

// The start Time is define when launching.
fileprivate let _startTime = AbsoluteTimeGetCurrent()

/// Returns the elapsed time since launch time.
///
/// - Returns: the elapsed tile
public func getElapsedTime()->Double {
    return AbsoluteTimeGetCurrent() - _startTime
}

#if os(Linux)
    public class Progress {
        public var totalUnitCount: Int64 = 0
        public var completedUnitCount: Int64 = 0
        public init(){
        }
    }


    public func NSLocalizedString(_ key: String, tableName: String, comment: String) -> String{
        return key   // @Todo Linux
    }


#endif

