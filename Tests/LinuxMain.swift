import XCTest
@testable import BartlebyCoreTests

XCTMain([
    testCase(BartlebyCoreTests.allTests),
    testCase(ObjectCollectionTests.allTests)
    testCase(DataPointTests.allTests)
])
