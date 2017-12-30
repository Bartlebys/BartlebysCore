//
//  DataPointTests.swift
//  BartlebysCoreTests
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import XCTest
@testable import BartlebysCore


extension ManagedModel:Tolerent{
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
    }
}


class MyDataPoint: DataPoint {

    public enum FileNames:String{
        case metrics
        case managedModels
    }

    public var playerId: String { return session.sessionIdentifier }

    // MARK: -  Collections of Models proxys
    public var metricsCollection: CollectionOf<Metrics> =  CollectionOf<Metrics>(named:FileNames.metrics.rawValue,relativePath:"tests")

    public var managedModelsCollection: CollectionOf<ManagedModel> =  CollectionOf<ManagedModel>(named:FileNames.managedModels.rawValue,relativePath:"tests")

    override func registerCollections() throws {
        try super.registerCollections()
        try self.registerCollection(collection: self.metricsCollection)
        try self.registerCollection(collection: self.managedModelsCollection )
    }

}

class DataPointTests: XCTestCase{

    // MARK: - Tests

    static var allTests = [
        ("test001SaveDataPointAndReloadItsClone", test001SaveDataPointAndReloadItsClone),
        ("test002CollectionsReferences", test002CollectionsReferences),
        ("test003SimpleRelations", test003SimpleRelations),
        ("test004RelationalErasure", test004RelationalErasure),
        ]


    

    func test001SaveDataPointAndReloadItsClone() {


        let expectation = XCTestExpectation(description: "Save And ReloadADataPoint")

        // This test is asynchronous
        // We need to use storage observers

        do {

            let datapoint = try MyDataPoint(baseURL: Paths.baseDirectoryURL)
            let metricsFileName = MyDataPoint.FileNames.metrics.rawValue
            let managedModelsFileName = MyDataPoint.FileNames.managedModels.rawValue

            // -----------------------------------
            // 1# Create or load the collection

            let loadHandler = StorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                if !success{
                    XCTFail("Metrics loading did fail: \(String(describing: message)) ")
                    expectation.fulfill()
                }else{

                    if fileName == metricsFileName{

                        // We associate the metricsCollection Proxy with the loaded collection
                        datapoint.metricsCollection =? datapoint.collection(with: fileName)

                        // -----------------------------------
                        // 2# Populate some data
                        // Let's append a metrics
                        let metrics = Metrics()
                        metrics.operationName = "op"
                        datapoint.metricsCollection.append(metrics)

                        do{

                            // __
                            // 3# Save the data Point
                            // Let's save the DataPoint

                            let saveHandler = StorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                                // We reset the observer
                                if !success{
                                    XCTFail("datapoint.save() did fail: \(String(describing: message)) ")
                                    expectation.fulfill()
                                }else{
                                    if fileName == metricsFileName{
                                        do{

                                            // -----------------------------------
                                            // 4# create a clone and reload the data
                                            //we want to load a copy of the dataPoint

                                            let dataPointClone =  try MyDataPoint(baseURL: Paths.baseDirectoryURL)

                                            let reloadHandler = StorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                                                if !success{
                                                    XCTFail("Metrics createOrLoadCollection did fail: \(String(describing: message)) ")
                                                    expectation.fulfill()
                                                }else{
                                                    if fileName == metricsFileName{
                                                        XCTAssert(fileName == metricsFileName, "file name should be \"\(metricsFileName)\", current value: \(fileName)")
                                                        if let _ = datapoint.metricsCollection.index(where: { $0.id == metrics.id }) {
                                                            expectation.fulfill()
                                                        } else {
                                                            XCTFail("Metrics not found in the clone")
                                                            expectation.fulfill()
                                                        }
                                                    }else{
                                                        ///
                                                    }
                                                }
                                            })

                                            dataPointClone.storage.addProgressObserver(observer: reloadHandler)

                                        }catch{
                                            XCTFail("DataPoint clone creation error: \(error)")
                                            expectation.fulfill()
                                        }
                                    }else{
                                        XCTAssert(fileName == managedModelsFileName, "file name should be \"\(managedModelsFileName)\", current value: \(fileName)")
                                    }

                                }
                            })

                            try datapoint.save()
                            datapoint.storage.addProgressObserver(observer: saveHandler)

                        }catch{
                            XCTFail("Metrics collection save error: \(error)")
                            expectation.fulfill()
                        }
                    }
                }
            })


            // We set up an observer  the metrics when loaded
            datapoint.storage.addProgressObserver(observer:loadHandler)
        } catch {
            XCTFail("Metrics collection error: \(error)")
        }
        wait(for: [expectation], timeout: 5.0)
    }



    func test002CollectionsReferences() {
        do {
            let datapoint = try MyDataPoint(baseURL: Paths.baseDirectoryURL)
            let _ = MyDataPoint.FileNames.metrics.rawValue
            let metrics = Metrics()
            metrics.operationName = "op"
            datapoint.metricsCollection.append(metrics)

            let collection:CollectionOf<Metrics> = metrics.getCollection()
            XCTAssert(collection.contains(metrics) , "Retrived Collection should contains the metric")

            XCTAssert(collection.dataPoint?.sessionIdentifier == datapoint.sessionIdentifier , "The collection should be referencing its datapoint")

        }catch{
            XCTFail("Metrics collection error: \(error)")
        }
    }


    func test003SimpleRelations() {
        do {
            let datapoint = try MyDataPoint(baseURL: Paths.baseDirectoryURL)
            let _ = MyDataPoint.FileNames.metrics.rawValue

            let metrics1 = Metrics()
            metrics1.operationName = "op1"
            datapoint.metricsCollection.append(metrics1)

            let o = ManagedModel()
            datapoint.managedModelsCollection.append(o)

            metrics1.declaresOwnership(of: o)

            guard let ownerOfO:Metrics = o.firstRelation(Relationship.ownedBy) else{
                XCTFail("o should be owned by a metrics")
                return
            }
            
            XCTAssert(ownerOfO == metrics1, "metrics1 should be the owner of o")
        }catch{
            XCTFail("\(error)")
        }
    }


    func test004RelationalErasure() {
        do {
            let datapoint = try MyDataPoint(baseURL: Paths.baseDirectoryURL)
            let _ = MyDataPoint.FileNames.metrics.rawValue

            let metrics1 = Metrics()
            let mUID = metrics1.UID
            metrics1.operationName = "op1"
            datapoint.metricsCollection.append(metrics1)

            let o = ManagedModel()
            let oUID = o.UID
            datapoint.managedModelsCollection.append(o)

            metrics1.declaresOwnership(of: o)

            XCTAssert(datapoint.managedModelsCollection.count == 1, "managedModelsCollection should contain one item")
            XCTAssert(datapoint.metricsCollection.count == 1, "metricsCollection should contain one item")

            // Erasing the metrics should erase the managedModel
            try metrics1.erase()

            XCTAssert(datapoint.managedModelsCollection.count == 0, "managedModelsCollection should contain 0 item")
            XCTAssert(datapoint.metricsCollection.count == 0, "metricsCollection should contain 0 item")


            do{
                let _:ManagedModel = try datapoint.registredObjectByUID(oUID)
                let _:Metrics = try datapoint.registredObjectByUID(mUID)
                XCTFail("o and metric1 should not be registred")
            }catch DataPointError.instanceNotFound {
                // OK
            }catch{
                XCTFail("Should be DataPointError.instanceNotFound, current error is: \(error)")
            }

        }catch{
            XCTFail("\(error)")
        }
    }


    func test005RelationalLeafErasure() {
        
        do {
            let datapoint = try MyDataPoint(baseURL: Paths.baseDirectoryURL)
            let _ = MyDataPoint.FileNames.metrics.rawValue

            let metrics1 = Metrics()
            metrics1.operationName = "op1"
            datapoint.metricsCollection.append(metrics1)

            let o = ManagedModel()
            datapoint.managedModelsCollection.append(o)
            metrics1.declaresOwnership(of: o)

            let oUID = o.UID

            let oRef:ManagedModel = try datapoint.registredObjectByUID(oUID)
            XCTAssert(oRef == o, "o should be registred")

            XCTAssert(datapoint.managedModelsCollection.count == 1, "managedModelsCollection should contain one item")
            XCTAssert(datapoint.metricsCollection.count == 1, "metricsCollection should contain one item")

            // Erasing the o should not erase the managed model
            try o.erase()

            XCTAssert(datapoint.managedModelsCollection.count == 0, "managedModelsCollection should contain 0 item")
            XCTAssert(datapoint.metricsCollection.count == 1, "metricsCollection should contain 1 item")

            do{
                let _:ManagedModel = try datapoint.registredObjectByUID(oUID)
                XCTFail("oRef should not be registred")
            }catch DataPointError.instanceNotFound {
                // OK
            }catch{
                XCTFail("Should be DataPointError.instanceNotFound, current error is: \(error)")
            }

        }catch{
            XCTFail("\(error)")
        }
    }


}
