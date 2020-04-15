import RoutingKit
import XCTest

final class RouterTests: XCTestCase {
    func testRouter() throws {
        let router = TrieRouter(Int.self)
        router.register(42, at: ["foo", "bar", "baz", ":user"])
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: &params), 42)
        XCTAssertEqual(params.get("user"), "Tanner")
    }
    
    func testCaseSensitiveRouting() throws {
        let router = TrieRouter<Int>()
        router.register(42, at: [.constant("path"), .constant("TO"), .constant("fOo")])
        var params = Parameters()
        XCTAssertNil(router.route(path: ["PATH", "tO", "FOo"], parameters: &params))
        XCTAssertEqual(router.route(path: ["path", "TO", "fOo"], parameters: &params), 42)
    }
    
    func testCaseInsensitiveRouting() throws {
        let router = TrieRouter<Int>(options: [.caseInsensitive])
        router.register(42, at: [.constant("path"), .constant("TO"), .constant("fOo")])
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: &params), 42)
    }

    func testAnyRouting() throws {
        let router = TrieRouter<Int>()
        router.register(0, at: [.constant("a"), .anything])
        router.register(1, at: [.constant("b"), .parameter("1"), .anything])
        router.register(2, at: [.constant("c"), .parameter("1"), .parameter("2"), .anything])
        router.register(3, at: [.constant("d"), .parameter("1"), .parameter("2")])
        router.register(4, at: [.constant("e"), .parameter("1"), .catchall])
        router.register(5, at: [.anything, .constant("e"), .parameter("1")])

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

    func testRouterSuffixes() throws {
        let router = TrieRouter<Int>(options: [.caseInsensitive])
        router.register(1, at: [.constant("a")])
        router.register(2, at: [.constant("aa")])

        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a"], parameters: &params), 1)
        XCTAssertEqual(router.route(path: ["aa"], parameters: &params), 2)
    }


    func testDocBlock() throws {
        let router = TrieRouter<Int>()
        router.register(42, at: ["users", ":user"])

        var params = Parameters()
        XCTAssertEqual(router.route(path: ["users", "Tanner"], parameters: &params), 42)
        XCTAssertEqual(params.get("user"), "Tanner")
    }

    func testDocs() throws {
        let router = TrieRouter(Double.self)
        router.register(42, at: ["fun", "meaning_of_universe"])
        router.register(1337, at: ["fun", "leet"])
        router.register(3.14, at: ["math", "pi"])
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["fun", "meaning_of_universe"], parameters: &params), 42)
    }

    func testDocs2() throws {
        let router = TrieRouter(String.self)
        router.register("show_user", at: [.constant("users"), .parameter("user_id")])

        var params = Parameters()
        _ = router.route(path: ["users", "42"], parameters: &params)
        print(params)
    }
    
    // https://github.com/vapor/routing/issues/64
    func testParameterPercentDecoding() throws {
        let router = TrieRouter(String.self)
        router.register("c", at: [.constant("a"), .parameter("b")])
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a", "te%20st"], parameters: &params), "c")
        XCTAssertEqual(params.get("b"), "te st")
    }

    // https://github.com/vapor/routing-kit/issues/74
    func testCatchAllNested() throws {
        let router = TrieRouter(String.self)
        router.register("/**", at: [.catchall])
        router.register("/a/**", at: ["a", .catchall])
        router.register("/a/b/**", at: ["a", "b", .catchall])
        router.register("/a/b", at: ["a", "b"])
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a"], parameters: &params), "/**")
        XCTAssertEqual(router.route(path: ["a", "b"], parameters: &params), "/a/b")
        XCTAssertEqual(router.route(path: ["a", "b", "c"], parameters: &params), "/a/b/**")
        XCTAssertEqual(router.route(path: ["a", "c"], parameters: &params), "/a/**")
        XCTAssertEqual(router.route(path: ["b"], parameters: &params), "/**")
        XCTAssertEqual(router.route(path: ["b", "c", "d", "e"], parameters: &params), "/**")
    }

    func testCatchAllPrecedence() throws {
        let router = TrieRouter(String.self)
        router.register("a", at: ["v1", "test"])
        router.register("b", at: ["v1", .catchall])
        router.register("c", at: ["v1", .anything])
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["v1", "test"], parameters: &params), "a")
        XCTAssertEqual(router.route(path: ["v1", "test", "foo"], parameters: &params), "b")
        XCTAssertEqual(router.route(path: ["v1", "foo"], parameters: &params), "c")
    }
    
    func testRouterDescription() throws {
        // Use simple routing to eliminate the impact of registration order
        let constA: PathComponent = "a"
        let constOne: PathComponent = "1"
        let paramOne: PathComponent = .parameter("1")
        let anything: PathComponent = .anything
        let catchall: PathComponent = .catchall
        let router = TrieRouter<Int>()
        router.register(0, at: [constA, anything])
        router.register(1, at: [constA, constOne, catchall])
        router.register(2, at: [constA, constOne, anything])
        router.register(3, at: [anything, constA, paramOne])
        router.register(4, at: [catchall])
        // Manually build description
        let desc = """
            → \(constA)
              → \(constOne)
                → \(anything)
                → \(catchall)
              → \(anything)
            → \(anything)
              → \(constA)
                → \(paramOne)
            → \(catchall)
            """
        XCTAssertEqual(router.description, desc)
    }
}
