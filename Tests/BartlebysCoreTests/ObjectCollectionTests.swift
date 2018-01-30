//
//  CollectionOfTest.swift
//  CollectionOfTests
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import XCTest
#if !USE_EMBEDDED_MODULES
    @testable import BartlebysCore
#endif


class ObjectCollectionTests: BaseDataPointTestCase{
    
    // MARK: - Tests
    
    static var allTests = [
        ("test001_Subscript", test001_Subscript),
        ("test002_Append", test002_Append),
        ("test003_Remove", test003_Remove),
        ("test004_Remove", test004_Remove),
        ("test005_Count", test005_Count),
        ("test006_UnicityOnUpserts",test006_UnicityOnUpserts),
        ("test007_PluralityOnAppends",test007_PluralityOnAppends),
        // ("test008_Selection_persistency",test008_Selection_persistency), /// XCTestExpectation fails on Linux
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
        
        // Use the factory
        let metrics1:Metrics = dataPoint.newInstance()
        metrics1.operationName = "operation1"
        
        // Use the factory
        let metrics2 = dataPoint.newInstance() as Metrics
        metrics2.operationName = "operation2"
        
        // Create and append
        let metrics3 = Metrics()
        collection.append(metrics3)
        metrics3.operationName = "operation3"
        
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
        
        let _ :Metrics = dataPoint.newInstance()
        
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        
    }
    
    func test003_Remove() {
        
        let dataPoint = self.getNewDataPoint()
        let collection = dataPoint.metricsCollection
        
        let _ = dataPoint.new(type: Metrics.self)
        
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        collection.remove(at: 0)
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")


        let m2 = dataPoint.new(type: Metrics.self)
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        do{
            try collection.removeItem(m2)
        }catch{
            XCTFail("\(error)")
        }
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")

        let typeMissMatch = dataPoint.new(type: LogEntry.self)
        do{
            try collection.removeItem(typeMissMatch)
            XCTFail("Should Fail on removeItm typeMissMatch")
        }catch{
            // Silent catch
        }

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
    
    #if !os(Linux)
    
    func test008_Selection_persistency(){
        
        let expectation = XCTestExpectation(description: "Selection")
        
        let myDataPoint = self.getNewDataPoint()
        let collection = myDataPoint.metricsCollection
        
        
        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        let metrics2 = Metrics()
        metrics2.operationName = "op2"
        let metrics3 = Metrics()
        metrics3.operationName = "op3"
        
        collection.append(metrics1)
        collection.append(metrics2)
        collection.append(metrics3)
        
        // select some items
        collection.selectedItems = [metrics3,metrics1]
        
        
        // The delegate encapsulates the tests logic
        struct Test008Delegate:DataPointLifeCycle{
            
            var expectation:XCTestExpectation
            var collection:CollectionOf<Metrics>
            var myDataPoint:MyDataPoint
            var metrics1UID:String
            var metrics3UID:String
            
            func collectionsDidLoadSuccessFully(dataPoint: DataPointProtocol){
                guard let dataPoint = dataPoint as? MyDataPoint else{
                    XCTFail("DataPoint type Miss Match")
                    return
                }
                do {
                    try dataPoint.save()
                }catch{
                    XCTFail("\(error)")
                }
            }
            func collectionsDidFailToLoad(dataPoint: DataPointProtocol,message:String){
                XCTFail("collectionDidFailToLoad: \(message)")
                expectation.fulfill()
            }
            
            func collectionsDidSaveSuccessFully(dataPoint: DataPointProtocol){
                
                guard let dataPoint = dataPoint as? MyDataPoint else{
                    XCTFail("DataPoint type Miss Match")
                    return
                }
                
                // That's the main test
                // The collection has been saved
                // Let's reload after
                // reseting the selectedItems
                // cleaning up the key data Storage
                
                self.collection.selectedItems = [Metrics]()
                self.myDataPoint.keyedDataCollection.removeAll()
                
                let reloadHandler = AutoRemovableStorageProgressHandler(dataPoint: dataPoint, handler: {  (fileName, success, message, progress) in
                    if !success{
                        XCTFail("datapoint.load() did fail: \(String(describing: message)) ")
                    }else{
                        print("progress.totalUnitCount \(progress.totalUnitCount) progress.completedUnitCount  \(progress.completedUnitCount)")
                        if progress.totalUnitCount > self.myDataPoint.collectionsCount(){
                            XCTFail("progress.totalUnitCount \(progress.totalUnitCount) >  dataPoint.collectionsCount  \(self.myDataPoint.collectionsCount())")
                        }
                        if progress.completedUnitCount == progress.totalUnitCount{
                            // It is finished
                            guard let selectedItems = self.myDataPoint.metricsCollection.selectedItems else{
                                XCTFail("Void metricsCollection.selectedItems")
                                return
                            }
                            XCTAssert(selectedItems.count == 2,"selectedItems.count == \(selectedItems.count) should be equal to 2" )
                            XCTAssert(selectedItems.filter{ $0.operationName == "op3"}.count == 1, "Should contain a op3")
                            XCTAssert(selectedItems.filter{ $0.operationName == "op1"}.count == 1, "Should contain a op1")
                            XCTAssert(selectedItems.filter{ $0.uid == self.metrics3UID }.count == 1, "Should contain metrics3")
                            XCTAssert(selectedItems.filter{ $0.uid == self.metrics1UID }.count == 1, "Should contain metrics1")
                            self.expectation.fulfill()
                        }
                    }
                })
                do{
                    
                    
                    
                    // Reload the metrics
                    try self.myDataPoint.storage.loadCollection(on: self.myDataPoint.keyedDataCollection)
                    try self.myDataPoint.storage.loadCollection(on: self.myDataPoint.metricsCollection)
                    dataPoint.storage.addProgressObserver(observer: reloadHandler)
                }catch{
                    XCTFail("\(error)")
                }
                
            }
            
            func collectionsDidFailToSave(dataPoint: DataPointProtocol,message:String){
                XCTFail("collectionDidFailToSave: \(message)")
                expectation.fulfill()
            }
        }
        
        // We use a special delegate
        myDataPoint.delegate = Test008Delegate(expectation: expectation,
                                               collection: collection,
                                               myDataPoint: myDataPoint,
                                               metrics1UID: metrics1.uid,
                                               metrics3UID: metrics3.uid)
        
        
        wait(for: [expectation], timeout: 5.0)
    }
    #endif
    
}
