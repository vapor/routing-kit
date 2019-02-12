#if os(Linux)

import XCTest
@testable import RoutingKitTests

XCTMain([
    testCase(RouterTests.allTests),
])

#endif
