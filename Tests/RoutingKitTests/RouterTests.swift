import RoutingKit
import XCTest

public final class RouterTests: XCTestCase {
    public func testRouter() throws {
        let route = Route(path: ["foo", "bar", "baz", User.parameter], output: 42)
        let router = TrieRouter(Int.self)
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: &params), 42)
        try XCTAssertEqual(params.next(User.self).name, "Tanner")
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
        let route0 = Route<Int>(path: [.constant("a"), any], output: 0)
        let route1 = Route<Int>(path: [.constant("b"), .parameter("1"), any], output: 1)
        let route2 = Route<Int>(path: [.constant("c"), .parameter("1"), .parameter("2"), any], output: 2)
        let route3 = Route<Int>(path: [.constant("d"), .parameter("1"), .parameter("2")], output: 3)
        let route4 = Route<Int>(path: [.constant("e"), .parameter("1"), all], output: 4)
        let route5 = Route<Int>(path: [any, .constant("e"), .parameter("1")], output: 5)

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
        let route = Route<Int>(path: [.constant("users"), User.parameter], output: 42)
        let router = TrieRouter<Int>()
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["users", "Tanner"], parameters: &params), 42)
        try XCTAssertEqual(params.next(User.self).name, "Tanner")
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
    
    // MARK: Performance
    
    public func testCaseSensitivePerformance() throws {
        print()
        print("[EXPECTED] average: 0.024, relative standard deviation: 5.642%")
        let router = TrieRouter(String.self)
        for letter in ["a", "b", "c", "d", "e" , "f", "g"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
       
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a", "42"], parameters: &params)
            }
        }
    }
    
    public func testCaseInsensitivePerformance() throws {
        print()
        print("[EXPECTED] average: 0.032, relative standard deviation: 0.869%")
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a", "b", "c", "d", "e" , "f", "g"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a", "42"], parameters: &params)
            }
        }
    }
    
    public func testCaseInsensitiveRoutingMatchFirstPerformance() throws {
        print()
        print("[EXPECTED] average: 0.045, relative standard deviation: 0.264%")
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae" , "aaaaaaaf", "aaaaaaag"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["aaaaaaaa", "42"], parameters: &params)
            }
        }
    }
    
    public func testCaseInsensitiveRoutingMatchLastPerformance() throws {
        print()
        print("[EXPECTED] average: 0.046, relative standard deviation: 0.086%")
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae" , "aaaaaaaf", "aaaaaaag"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["aaaaaaag", "42"], parameters: &params)
            }
        }
    }
    
    public func testMinimalRouterCaseSensitivePerformance() throws {
        print()
        print("[EXPECTED] average: 0.016, relative standard deviation: 0.046%")
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a"] {
            router.register(route: Route(path: [
                .constant(letter)
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a"], parameters: &params)
            }
        }
    }
    
    public func testMinimalRouterCaseInsensitivePerformance() throws {
        print()
        print("[EXPECTED] average: 0.021, relative standard deviation: 0.800%")
        let router = TrieRouter.init(String.self)
        for letter in ["a"] {
            router.register(route: Route(path: [
                .constant(letter)
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a"], parameters: &params)
            }
        }
    }
    
    
    public func testMinimalEarlyFailPerformance() throws {
        print()
        print("[EXPECTED] average: 0.013, relative standard deviation: 4.608%")
        let router = TrieRouter.init(String.self)
        for letter in ["aaaaaaaaaaaaaa"] {
            router.register(route: Route(path: [
                .constant(letter)
            ], output: letter))
        }

        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["baaaaaaaaaaaaa"], parameters: &params)
            }
        }
    }


    public static let allTests = [
        ("testRouter", testRouter),
        ("testCaseInsensitiveRouting", testCaseInsensitiveRouting),
        ("testCaseSensitiveRouting", testCaseSensitiveRouting),
        ("testAnyRouting", testAnyRouting),
        ("testRouterSuffixes", testRouterSuffixes),
        ("testCaseSensitivePerformance", testCaseSensitivePerformance),
        ("testCaseInsensitivePerformance", testCaseInsensitivePerformance),
        ("testCaseInsensitiveRoutingMatchFirstPerformance", testCaseInsensitiveRoutingMatchFirstPerformance),
        ("testCaseInsensitiveRoutingMatchLastPerformance", testCaseInsensitiveRoutingMatchLastPerformance),
        ("testMinimalRouterCaseInsensitivePerformance", testMinimalRouterCaseInsensitivePerformance),
        ("testMinimalRouterCaseSensitivePerformance", testMinimalRouterCaseSensitivePerformance),
        ("testMinimalEarlyFailPerformance", testMinimalEarlyFailPerformance),
    ]
}

final class User: Parameter {
    var name: String

    init(name: String) {
        self.name = name
    }

    static func resolveParameter(_ parameter: String) throws -> User {
        let user = User(name: parameter)
        return user
    }
}
