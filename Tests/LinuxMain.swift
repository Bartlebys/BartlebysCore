import XCTest
@testable import BartlebyCoreTests

XCTMain([
    testCase(DataPointTests.allTests),
    testCase(ObjectCollectionTests.allTests),
    testCase(AliasesTests.allTests),
    testCase(RelationsTests.allTests),
    testCase(DataPointKVS.allTests)
])
