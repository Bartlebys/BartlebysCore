//
//  DataPointTests.swift
//  BartlebysCoreTests
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import XCTest

#if !USE_EMBEDDED_MODULES
    @testable import BartlebysCore
#endif


fileprivate struct PersistentSample:Codable,Initializable,FilePersistent{


    var x:Int = 0

    // MARK: - Initializable
    init() {}

    //MARK: - FilePersistent

    var fileName: String = "Sample"

    var relativeFolderPath: String = Default.VOID_STRING

}


class DataPointTests: BaseDataPointTestCase{

    // MARK: - Tests

    static var allTests = [
        ("test001_SaveDataPointAndReloadItsClone", test001_SaveDataPointAndReloadItsClone),
        ("test002_CollectionsReferences", test002_CollectionsReferences),
    ]

    

    func test001_SaveDataPointAndReloadItsClone() {


        let expectation = XCTestExpectation(description: "Save And ReloadADataPoint")

        // This test is asynchronous
        // We need to use storage observers


            /// This test is special
            /// We donot want to prepare the collections to prevent
            let datapoint = self.getNewDataPoint()

            let metricsFileName = MyDataPoint.FileNames.metrics.rawValue
            let managedModelsFileName = MyDataPoint.FileNames.models.rawValue

            // -----------------------------------
            // 1# Create or load the collection

            let loadHandler = AutoRemovableStorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                if !success{
                    XCTFail("Metrics loading did fail: \(String(describing: message)) ")
                    expectation.fulfill()
                }else{

                    if progress.totalUnitCount == progress.completedUnitCount{

                        // We associate the metricsCollection Proxy with the loaded collection
                        datapoint.metricsCollection =? datapoint.collection(with: datapoint.metricsCollection.fileName)

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

                            let saveHandler = AutoRemovableStorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
                                // We reset the observer
                                if !success{
                                    XCTFail("datapoint.save() did fail: \(String(describing: message)) ")
                                    expectation.fulfill()
                                }else{

                                    if fileName == metricsFileName{

                                            // -----------------------------------
                                            // 4# create a clone and reload the data
                                            //we want to load a copy of the dataPoint

                                            let dataPointClone = self.getNewDataPoint()
                                            dataPointClone.sessionIdentifier = datapoint.sessionIdentifier
                                        
                                            let reloadHandler = AutoRemovableStorageProgressHandler(dataPoint: datapoint, handler: {  (fileName, success, message, progress) in
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

                                      
                                    }else{
                                        XCTAssert(fileName == managedModelsFileName, "file name should be \"\(managedModelsFileName)\", current value: \(fileName)")
                                    }

                                }
                            })

                            datapoint.storage.addProgressObserver(observer: saveHandler)
                            try datapoint.save()

                        }catch{
                            XCTFail("Metrics collection save error: \(error)")
                            expectation.fulfill()
                        }
                    }
                }
            })

            // We set up an observer  the metrics when loaded
            datapoint.storage.addProgressObserver(observer:loadHandler)


        wait(for: [expectation], timeout: 5.0)
    }



    func test002_CollectionsReferences() {
        do {
            let datapoint = MyDataPoint()
            try datapoint.prepareCollections(volatile: false)
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



    func test003_saveAndLoadSync(){


    }



}
