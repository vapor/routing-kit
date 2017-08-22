#if os(Linux)

import XCTest
@testable import RoutingTests

XCTMain([
    testCase(RouterTests.allTests),
])

#endif
