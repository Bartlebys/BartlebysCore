//
//  DataPoint+HTTP.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 12/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public enum DataPointHTTPError:Error{
    case invalidStatus(statusCode:Int)
    case responseCastingError(response:URLResponse?, error: Error?)
}

// Actually (swift 4.2) Swift extensions cannot be overriden outside of their module.
// So we have move the HTTP Implementation to Datapoint.swift
// To enable external module to override the HTTP implementation.
// For example to hook refresh Token in OAUTH

// MARK: - Download / Uploads

extension DataPoint{

    public func cancelUploads(){
        self.downloads.removeAll()
    }
    public func cancelDownloads(){
        self.uploads.removeAll()
    }
}

