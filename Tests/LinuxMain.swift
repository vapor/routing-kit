#if os(Linux)

import XCTest
import RoutingKitTests

XCTMain([
    testCase(RouterTests.allTests),
])

#endif
