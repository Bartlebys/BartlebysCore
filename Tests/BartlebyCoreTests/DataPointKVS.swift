//
//  DataPointKVS.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 07/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import XCTest
@testable import BartlebysCore

class DataPointKVS: BaseDataPointTestCase {


    static var allTests = [
        ("test001_StoreACodable", test001_StoreACodable),
    ]

    func test001_StoreACodable() {
        let dataPoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        // Note that We do not add the metric to the collection

        do{
            try dataPoint.storeInKVS(metrics1, identifiedBy: "Metric1")
            let metrics1Copy:Metrics = try dataPoint.getFromKVS(key: "Metric1")
            XCTAssert(metrics1Copy.operationName == "op1", "Should be op1: \(metrics1Copy.operationName)")
        }catch{
            XCTFail("\(error)")
        }
    }
}
