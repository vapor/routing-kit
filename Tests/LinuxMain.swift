#if os(Linux)

import XCTest
import RouterTests

XCTMain([
    testCase(RouterTests.allTests),
])

#endif
