//
//  RouteExtractionTests.swift
//  Routing
//
//  Created by Logan Wright on 11/1/16.
//
//

import XCTest
@testable import Routing

class RouteExtractionTests: XCTestCase {
    func testRouteLog() throws {
        let base = Branch<Int>(name: "a")
        XCTAssertEqual(base.route, "/a")

        let extended = base.extend(["b", "c"], output: 2)
        XCTAssertEqual(extended.route, "/a/b/c")

        let wild = base.extend(["*", ":foo"], output: 3)
        XCTAssertEqual(wild.route, "/a/*/:foo")
    }

    func testIndividualBranches() throws {
        let a = Branch<Int>(name: "a")
        let b = Branch<Int>(name: "b")
        let c = Branch<Int>(name: "c")
        let d = Branch<Int>(name: "d")
        let e = Branch<Int>(name: "e")

        a.testableSetBranch(key: "b", branch: b)
        a.testableSetBranch(key: "c", branch: c)
        c.testableSetBranch(key: "d", branch: d)
        c.testableSetBranch(key: "e", branch: e)

        let allBranches = a.allIndividualBranchesInTreeIncludingSelf.map { $0.name }
        XCTAssertEqual(allBranches, [a, b, c, d, e].map { $0.name })
    }


    func testIndividualBranchesWithOutput() throws {
        let a = Branch<Int>(name: "a", output: 1)
        let b = Branch<Int>(name: "b")
        let c = Branch<Int>(name: "c", output: 2)
        let d = Branch<Int>(name: "d")
        let e = Branch<Int>(name: "e", output: 3)

        a.testableSetBranch(key: "b", branch: b)
        a.testableSetBranch(key: "c", branch: c)
        c.testableSetBranch(key: "d", branch: d)
        c.testableSetBranch(key: "e", branch: e)

        let allBranches = a.allBranchesWithOutputIncludingSelf.map { $0.name }
        XCTAssertEqual(allBranches, [a, c, e].map { $0.name })
    }

    func testBranchRoutes() throws {
        let a = Branch<Int>(name: "a", output: 1)
        let b = Branch<Int>(name: "b")
        let c = Branch<Int>(name: "c", output: 2)
        let d = Branch<Int>(name: "d")
        let e = Branch<Int>(name: "e", output: 3)

        a.testableSetBranch(key: "b", branch: b)
        a.testableSetBranch(key: "c", branch: c)
        c.testableSetBranch(key: "d", branch: d)
        c.testableSetBranch(key: "e", branch: e)

        let expectation = ["/a", "/a/c", "/a/c/e"]
        XCTAssertEqual(a.routes, expectation)
    }
}
