#if os(Linux)

import XCTest
@testable import RoutingTests
@testable import BranchesTests

XCTMain([
    // Branches
    testCase(BranchTests.allTests),
    testCase(RouteExtractionTests.allTests),

    // Routing
    testCase(AddTests.allTests),
    testCase(GroupedTests.allTests),
    testCase(GroupTests.allTests),
    testCase(RouterTests.allTests),
    testCase(RouteTests.allTests),
])

#endif
