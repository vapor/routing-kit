import RoutingKit
import XCTest

public final class RouterTests: XCTestCase {
    public func testRouter() throws {
        let route = Route(path: ["foo", "bar", "baz", ":user"], output: 42)
        let router = TrieRouter(Int.self)
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: &params), 42)
        XCTAssertEqual(params.get("user"), "Tanner")
    }
    
    public func testCaseSensitiveRouting() throws {
        let route = Route<Int>(path: [.constant("path"), .constant("TO"), .constant("fOo")], output: 42)
        let router = TrieRouter<Int>()
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: &params), nil)
        XCTAssertEqual(router.route(path: ["path", "TO", "fOo"], parameters: &params), 42)
    }
    
    public func testCaseInsensitiveRouting() throws {
        let route = Route<Int>(path: [.constant("path"), .constant("TO"), .constant("fOo")], output: 42)
        let router = TrieRouter<Int>(options: [.caseInsensitive])
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: &params), 42)
    }

    public func testAnyRouting() throws {
        let route0 = Route<Int>(path: [.constant("a"), .anything], output: 0)
        let route1 = Route<Int>(path: [.constant("b"), .parameter("1"), .anything], output: 1)
        let route2 = Route<Int>(path: [.constant("c"), .parameter("1"), .parameter("2"), .anything], output: 2)
        let route3 = Route<Int>(path: [.constant("d"), .parameter("1"), .parameter("2")], output: 3)
        let route4 = Route<Int>(path: [.constant("e"), .parameter("1"), .catchall], output: 4)
        let route5 = Route<Int>(path: [.anything, .constant("e"), .parameter("1")], output: 5)

        let router = TrieRouter<Int>()
        router.register(route: route0)
        router.register(route: route1)
        router.register(route: route2)
        router.register(route: route3)
        router.register(route: route4)
        router.register(route: route5)

        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a", "b"], parameters: &params), 0)
        XCTAssertNil(router.route(path: ["a"], parameters: &params))
        XCTAssertEqual(router.route(path: ["a", "a"], parameters: &params), 0)
        XCTAssertEqual(router.route(path: ["b", "a", "c"], parameters: &params), 1)
        XCTAssertNil(router.route(path: ["b"], parameters: &params))
        XCTAssertNil(router.route(path: ["b", "a"], parameters: &params))
        XCTAssertEqual(router.route(path: ["b", "a", "c"], parameters: &params), 1)
        XCTAssertNil(router.route(path: ["c"], parameters: &params))
        XCTAssertNil(router.route(path: ["c", "a"], parameters: &params))
        XCTAssertNil(router.route(path: ["c", "b"], parameters: &params))
        XCTAssertEqual(router.route(path: ["d", "a", "b"], parameters: &params), 3)
        XCTAssertNil(router.route(path: ["d", "a", "b", "c"], parameters: &params))
        XCTAssertNil(router.route(path: ["d", "a"], parameters: &params))
        XCTAssertEqual(router.route(path: ["e", "1", "b", "a"], parameters: &params), 4)
        XCTAssertEqual(router.route(path: ["f", "e", "1"], parameters: &params), 5)
        XCTAssertEqual(router.route(path: ["g", "e", "1"], parameters: &params), 5)
        XCTAssertEqual(router.route(path: ["g", "e", "1"], parameters: &params), 5)
    }

    public func testRouterSuffixes() throws {
        let route1 = Route<Int>(path: [.constant("a")], output: 1)
        let route2 = Route<Int>(path: [.constant("aa")], output: 2)

        let router = TrieRouter<Int>(options: [.caseInsensitive])
        router.register(route: route1)
        router.register(route: route2)

        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a"], parameters: &params), 1)
        XCTAssertEqual(router.route(path: ["aa"], parameters: &params), 2)
    }


    public func testDocBlock() throws {
        let route = Route<Int>(path: ["users", ":user"], output: 42)
        let router = TrieRouter<Int>()
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["users", "Tanner"], parameters: &params), 42)
        XCTAssertEqual(params.get("user"), "Tanner")
    }

    public func testDocs() throws {
        let router = TrieRouter(Double.self)
        router.register(route: Route(path: ["fun", "meaning_of_universe"], output: 42))
        router.register(route: Route(path: ["fun", "leet"], output: 1337))
        router.register(route: Route(path: ["math", "pi"], output: 3.14))
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["fun", "meaning_of_universe"], parameters: &params), 42)
    }

    public func testDocs2() throws {
        let router = TrieRouter(String.self)
        router.register(route: Route(path: [.constant("users"), .parameter("user_id")], output: "show_user"))

        var params = Parameters()
        _ = router.route(path: ["users", "42"], parameters: &params)
        print(params)
    }
    
    // https://github.com/vapor/routing/issues/64
    public func testParameterPercentDecoding() throws {
        let router = TrieRouter(String.self)
        router.register(route: Route(path: [.constant("a"), .parameter("b")], output: "c"))
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a", "te%20st"], parameters: &params), "c")
        XCTAssertEqual(params.get("b"), "te st")
    }
    
    public func testGroupedRoutes() throws {
        let router = TrieRouter(Int.self)
        let prefixGroup = router.grouped([.constant("foo")])

        prefixGroup.register(route: Route(path: [.constant("bar")], output: 1))
        prefixGroup.register(route: Route(path: [.constant("baz")], output: 2))
        
        let feeGroup = prefixGroup.grouped([.constant("fee")])
        
        feeGroup.register(route: Route(path: [.constant("fi")], output: 3))
        
        var params = Parameters()
        
        XCTAssertEqual(router.route(path: ["foo", "bar"], parameters: &params), 1)
        XCTAssertEqual(router.route(path: ["foo", "baz"], parameters: &params), 2)
        XCTAssertEqual(router.route(path: ["foo", "fee", "fi"], parameters: &params), 3)
    }

    public static let allTests = [
        ("testRouter", testRouter),
        ("testCaseInsensitiveRouting", testCaseInsensitiveRouting),
        ("testCaseSensitiveRouting", testCaseSensitiveRouting),
        ("testAnyRouting", testAnyRouting),
        ("testDocBlock", testDocBlock),
        ("testDocs", testDocs),
        ("testDocs2", testDocs2),
        ("testParameterPercentDecoding", testParameterPercentDecoding),
    ]
}
