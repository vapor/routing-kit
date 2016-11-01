#if os(Linux)

import XCTest
@testable import RoutingTests
@testable import HTTPRoutingTests

XCTMain([
    // Routing
    testCase(BranchTests.allTests),
    testCase(RouteBuilderTests.allTests),
    testCase(RouteCollectionTests.allTests),
    testCase(RouterTests.allTests),
    testCase(RouteTests.allTests),
    testCase(RouteExtractionTests.allTests),

    // HTTPRouting
    testCase(AddTests.allTests),
    testCase(GroupedTests.allTests),
    testCase(GroupTests.allTests),
])

#endif
