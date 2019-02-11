#if os(Linux)

import XCTest
@testable import RouterTests

XCTMain([
    testCase(RouterTests.allTests),
])

#endif
