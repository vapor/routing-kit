//
//  RouteExtractionTests.swift
//  Routing
//
//  Created by Logan Wright on 11/1/16.
//
//

import XCTest
import Routing

class RouteExtractionTests: XCTestCase {
    func testRouteLog() throws {
        let base = Branch<Int>(name: "a")
        XCTAssertEqual(base.route, "/a")

        let extended = base.extend(["b", "c"], output: 2)
        XCTAssertEqual(extended.route, "/a/b/c")

        let wild = base.extend(["*", ":foo"], output: 3)
        XCTAssertEqual(wild.route, "/a/*/:foo")
    }
}
