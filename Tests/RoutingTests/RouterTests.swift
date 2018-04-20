import Routing
import XCTest

class RouterTests: XCTestCase {
    func testRouter() throws {
        let route = Route(path: ["foo", "bar", "baz", User.parameter], output: 42)
        let router = TrieRouter(Int.self)
        router.register(route: route)

        let container = BasicContainer(
            config: Config(),
            environment: .development,
            services: Services(),
            on: EmbeddedEventLoop()
        )
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: &params), 42)
        try XCTAssertEqual(params.next(User.self, on: container).wait().name, "Tanner")
    }
    
    func testCaseSensitiveRouting() throws {
        let route = Route<Int>(path: [.constant("path"), .constant("TO"), .constant("fOo")], output: 42)
        let router = TrieRouter<Int>()
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: &params), nil)
        XCTAssertEqual(router.route(path: ["path", "TO", "fOo"], parameters: &params), 42)
    }
    
    func testCaseInsensitiveRouting() throws {
        let route = Route<Int>(path: [.constant("path"), .constant("TO"), .constant("fOo")], output: 42)
        let router = TrieRouter<Int>(options: [.caseInsensitive])
        router.register(route: route)
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: &params), 42)
    }

    func testAnyRouting() throws {
        let route0 = Route<Int>(path: [.constant("a"), .anything], output: 0)
        let route1 = Route<Int>(path: [.constant("b"), .parameter("1"), .anything], output: 1)
        let route2 = Route<Int>(path: [.constant("c"), .parameter("1"), .parameter("2"), .anything], output: 2)
        let route3 = Route<Int>(path: [.constant("d"), .parameter("1"), .parameter("2")], output: 3)
        let route4 = Route<Int>(path: [.constant("e"), .parameter("1"), .anything], output: 4)

        let router = TrieRouter<Int>()
        router.register(route: route0)
        router.register(route: route1)
        router.register(route: route2)
        router.register(route: route3)
        router.register(route: route4)

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
    }

    func testRouterSuffixes() throws {
        let route1 = Route<Int>(path: [.constant("a")], output: 1)
        let route2 = Route<Int>(path: [.constant("aa")], output: 2)

        let router = TrieRouter<Int>(options: [.caseInsensitive])
        router.register(route: route1)
        router.register(route: route2)

        var params = Parameters()
        XCTAssertEqual(router.route(path: ["a"], parameters: &params), 1)
        XCTAssertEqual(router.route(path: ["aa"], parameters: &params), 2)
    }


    func testDocBlock() throws {
        let route = Route<Int>(path: [.constant("users"), User.parameter], output: 42)
        let router = TrieRouter<Int>()
        router.register(route: route)

        let container = BasicContainer(
            config: Config(),
            environment: .development,
            services: Services(),
            on: EmbeddedEventLoop()
        )
        var params = Parameters()
        XCTAssertEqual(router.route(path: ["users", "Tanner"], parameters: &params), 42)
        try XCTAssertEqual(params.next(User.self, on: container).wait().name, "Tanner")
    }

    func testDocs() throws {
        let router = TrieRouter(Double.self)
        router.register(route: Route(path: ["fun", "meaning_of_universe"], output: 42))
        router.register(route: Route(path: ["fun", "leet"], output: 1337))
        router.register(route: Route(path: ["math", "pi"], output: 3.14))

        var params = Parameters()
        XCTAssertEqual(router.route(path: ["fun", "meaning_of_universe"], parameters: &params), 42)
    }

    func testDocs2() throws {
        let router = TrieRouter(String.self)
        router.register(route: Route(path: [.constant("users"), .parameter("user_id")], output: "show_user"))

        var params = Parameters()
        _ = router.route(path: ["users", "42"], parameters: &params)
        print(params)
    }

    static let allTests = [
        ("testRouter", testRouter),
        ("testCaseInsensitiveRouting", testCaseInsensitiveRouting),
        ("testCaseSensitiveRouting", testCaseSensitiveRouting),
        ("testAnyRouting", testAnyRouting),
        ("testRouterSuffixes", testRouterSuffixes),
    ]
}

final class User: Parameter {
    var name: String

    init(name: String) {
        self.name = name
    }

    static func resolveParameter(_ parameter: String, on container: Container) throws -> Future<User> {
        let user = User(name: parameter)
        return container.eventLoop.newSucceededFuture(result: user)
    }
}
