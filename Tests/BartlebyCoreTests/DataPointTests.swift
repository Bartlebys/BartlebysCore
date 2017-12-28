//
//  DataPointTests.swift
//  BartlebysCoreTests
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import XCTest
#if os(iOS)
    @testable import BartlebysCoreiOS
#elseif os(macOS)
    @testable import BartlebysCore
#elseif os(Linux)
    @testable import BartlebysCore
#endif





class MyDataPoint: DataPoint {

    public enum FileNames:String{
        case metrics
    }

    public var playerId: String { return session.sessionIdentifier }


    // MARK: -  Collections of Models proxys
    public var metricsCollection: CollectionOf<Metrics> =  CollectionOf<Metrics>(named:FileNames.metrics.rawValue,relativePath:"tests")
    
    // MARK: - Main Initializer
    required public init(credentials: Credentials, sessionIdentifier: String, coder: ConcreteCoder,delegate:DataPointDelegate) throws {
        try super.init(credentials: credentials, sessionIdentifier: sessionIdentifier, coder: coder,delegate:delegate)
        try self.registerCollection(collection: metricsCollection)
    }

}

class DataPointTests: XCTestCase,DataPointDelegate{


    // MARK: - DataPointDelegate

    func collectionDifSaveSuccessFully() {}

    func collectionDidFailToSave(message: String) {}

    func collectionDidLoadSuccessFully() {}

    func collectionDidFailToLoad(message: String) {}

    // MARK: - Tests

    static var allTests = [
        ("test001SaveDataPointAndReloadItsClone", test001SaveDataPointAndReloadItsClone),
        ]


    

    func test001SaveDataPointAndReloadItsClone() {

        let expectation = XCTestExpectation(description: "Save And ReloadADataPoint")

        let uid = Utilities.createUID()

        // This test is asynchronous
        // We need to use storage observers

        do {

            let datapoint = try MyDataPoint(credentials: Credentials(username: "", password: ""), sessionIdentifier: uid, coder: JSONCoder(),delegate:self)
            let metricsFileName = MyDataPoint.FileNames.metrics.rawValue

            // -----------------------------------
            // 1# Create or load the collection

            let loadHandler = StorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                if !success{
                    XCTFail("Metrics loading did fail: \(String(describing: message)) ")
                    expectation.fulfill()
                }else{
                    XCTAssert(fileName == metricsFileName, "file name should be \"\(metricsFileName)\", current value: \(fileName)")

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
                                XCTAssert(fileName == metricsFileName, "file name should be \"\(metricsFileName)\", current value: \(fileName)")
                                do{

                                    // -----------------------------------
                                    // 4# create a clone and reload the data
                                    //we want to load a copy of the dataPoint

                                    let dataPointClone =  try MyDataPoint(credentials: Credentials(username: "", password: ""), sessionIdentifier: uid, coder: JSONCoder(), delegate: self)

                                    let reloadHandler = StorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                                        if !success{
                                            XCTFail("Metrics createOrLoadCollection did fail: \(String(describing: message)) ")
                                            expectation.fulfill()
                                        }else{
                                            XCTAssert(fileName == metricsFileName, "file name should be \"\(metricsFileName)\", current value: \(fileName)")
                                            if let _ = datapoint.metricsCollection.index(where: { $0.id == metrics.id }) {
                                                expectation.fulfill()
                                            } else {
                                                XCTFail("Metrics not found in the clone")
                                                expectation.fulfill()
                                            }
                                        }
                                    })
                                    
                                    dataPointClone.storage.addProgressObserver(observer: reloadHandler)

                                }catch{
                                    XCTFail("DataPoint clone creation error: \(error)")
                                    expectation.fulfill()
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
            })


            // We set up an observer  the metrics when loaded
            datapoint.storage.addProgressObserver(observer:loadHandler)
        } catch {
            XCTFail("Metrics collection error: \(error)")
        }
        wait(for: [expectation], timeout: 5.0)
    }



    func test002CollectionsReferences() {

        let uid = Utilities.createUID()
        do {
            let datapoint = try MyDataPoint(credentials: Credentials(username: "", password: ""), sessionIdentifier: uid, coder: JSONCoder(),delegate:self)
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
}
