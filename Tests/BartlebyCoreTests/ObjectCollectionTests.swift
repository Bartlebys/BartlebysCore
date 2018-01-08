//
//  CollectionOfTest.swift
//  CollectionOfTests
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import XCTest
@testable import BartlebysCore


class CollectionOfTests: BaseDataPointTestCase{

    // MARK: - Tests
    
    static var allTests = [
        ("test001_Subscript", test001_Subscript),
        ("test002_Append", test002_Append),
        ("test003_Remove", test003_Remove),
        ("test004_Remove", test004_Remove),
        ("test005_Count", test005_Count),
        ("test006_UnicityOnUpserts",test006_UnicityOnUpserts),
        ("test007_PluralityOnAppends",test007_PluralityOnAppends),
        ("test008_Selection_persistency",test008_Selection_persistency),
        ]
    
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    
    // MARK: -
    
    func test001_Subscript() {

        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics1 = Metrics()
        metrics1.operationName = "operation1"
        let metrics2 = Metrics()
        metrics2.operationName = "operation2"
        let metrics3 = Metrics()
        metrics3.operationName = "operation3"

        collection.append(metrics1)
        collection.append(metrics2)
        collection.append(metrics3)

        var metrics = collection[0]
        XCTAssert(metrics.operationName == "operation1", "The first element should be named \(metrics.operationName)")
        metrics = collection[1]
        XCTAssert(metrics.operationName == "operation2", "The second element should be named \(metrics.operationName)")
        metrics = collection[2]
        XCTAssert(metrics.operationName == "operation3", "The third element should be named \(metrics.operationName)")

        //collection[3]
        // managedmodel
    }
    
    func test002_Append() {
        
        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics = Metrics()
        collection.append(metrics)
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        
    }
    
    func test003_Remove() {

        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics = Metrics()
        collection.append(metrics)
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        collection.remove(at: 0)
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")
        
        // @todo remove qqch qui n'existe pas
    }
    
    func test004_Remove() {
        
        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics1 = Metrics()
        let metrics2 = Metrics()
        let metrics3 = Metrics()

        collection.append(metrics1)
        collection.append(metrics2)
        collection.append(metrics3)
        
        XCTAssert(collection.index(of: metrics1) == 0, "The index of metrics1 should be 0")
        XCTAssert(collection.index(of: metrics2) == 1, "The index of metrics2 should be 1")
        XCTAssert(collection.index(of: metrics3) == 2, "The index of metrics3 should be 2")

    }
    
    func test005_Count() {

        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        XCTAssert(collection.count == 0, "The collection should have exactly zero element")
        
        collection.append(Metrics())
        XCTAssert(collection.count == 1, "The collection should have exactly one element")

        collection.remove(at: 0)
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")
    }
    
    func test006_UnicityOnUpserts() {
        
        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics = Metrics()
        metrics.operationName = "operation"
        
        collection.upsert(metrics)
        Logger.log("Collection count = \(collection.count)")
        XCTAssert(collection.count == 1, "The collection should have exactly one element")

        collection.upsert(metrics)
        Logger.log("Collection count = \(collection.count)")
        XCTAssert(collection.count == 1, "The collection should still have exactly one element")
        
    }

    func test007_PluralityOnAppends() {

        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics = Metrics()
        metrics.operationName = "operation"

        collection.append(metrics)
        Logger.log("Collection count = \(collection.count)")
        XCTAssert(collection.count == 1, "The collection should have exactly one element")

        collection.append(metrics)
        Logger.log("Collection count = \(collection.count)")
        XCTAssert(collection.count == 2, "The collection should still have exactly two elements")

        if collection.count >= 2 {
            XCTAssert(collection[0] == collection[1] , "The two first elements should be equal")
            XCTAssert(collection[0] === collection[1] , "The two first elements should match")
        }
    }


    func test008_Selection_persistency(){

        let expectation = XCTestExpectation(description: "Selection")

        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection

        let metrics1 = Metrics()
        let metrics2 = Metrics()
        let metrics3 = Metrics()

        collection.append(metrics1)
        collection.append(metrics2)
        collection.append(metrics3)

        // select some items
        collection.selectedItems = [metrics3,metrics1]

        let saveHandler = AutoRemovableStorageProgressHandler(dataPoint: dataPoint, handler: {  (fileName, success, message, progress) in
            if !success{
                XCTFail("datapoint.save() did fail: \(String(describing: message))")
                expectation.fulfill()
            }else{

                if progress.totalUnitCount > dataPoint.collectionsCount(){
                    XCTFail("progress.totalUnitCount == \(progress.totalUnitCount)")
                    expectation.fulfill()
                }

                if progress.completedUnitCount == progress.totalUnitCount{

                    // It is finished
                    // Let's reload after
                    // reseting the selectedItems
                    // cleaning up the key data Storage
                    collection.selectedItems = [Metrics]()
                    while dataPoint.keyedDataCollection.count > 0{
                        dataPoint.keyedDataCollection.remove(at: 0)
                    }


                    let reloadHandler = AutoRemovableStorageProgressHandler(dataPoint: dataPoint, handler: {  (fileName, success, message, progress) in
                        if !success{
                            XCTFail("datapoint.load() did fail: \(String(describing: message)) ")
                            expectation.fulfill()
                        }else{
                            if fileName == dataPoint.metricsCollection.fileName{

                                if progress.completedUnitCount == progress.totalUnitCount{
                                    // It is finished

                                    guard let selectedItems = dataPoint.metricsCollection.selectedItems else{
                                        XCTFail("Void metricsCollection.selectedItems")
                                        expectation.fulfill()
                                        return
                                    }
                                    XCTAssert(selectedItems.count == 2,"selectedItems.count == \(selectedItems.count) should be equal to 2" )
                                    expectation.fulfill()
                                }
                            }
                        }
                    })
                    // Reload the metrics
                    dataPoint.storage.addProgressObserver(observer: reloadHandler)
                    dataPoint.storage.load(on: dataPoint.keyedDataCollection)
                    dataPoint.storage.load(on: dataPoint.metricsCollection)

                }
            }
        })

        do {
            dataPoint.storage.addProgressObserver(observer: saveHandler)
            try dataPoint.save()
        }catch{
            XCTFail("\(error)")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }



}
