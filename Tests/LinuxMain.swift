#if os(Linux)

import XCTest
import RoutingKitTests

XCTMain([
    testCase(RouterTests.allTests),
    testCase(RouterPerformanceTests.allTests)
])

#endif
