import Routing
import XCTest

class RouterTests: XCTestCase {
    func testRouter() throws {
        let route = Route<Int>(
            path: [.constant("foo"), .constant("bar"), .constant("baz"), User.parameter],
            output: 42
        )

        let router = TrieRouter<Int>()
        router.register(route: route)

        let container = BasicContainer(
            config: Config(),
            environment: .development,
            services: Services(),
            on: EmbeddedEventLoop()
        )
        let params = Params()
        XCTAssertEqual(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: params), 42)
        try XCTAssertEqual(params.parameters.next(User.self, on: container).wait().name, "Tanner")
    }
    
    func testCaseSensitiveRouting() throws {
        let route = Route<Int>(
            path: [.constant("path"), .constant("TO"), .constant("fOo")],
            output: 42
        )

        let router = TrieRouter<Int>()
        router.register(route: route)
        
        let params = Params()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: params), nil)
        XCTAssertEqual(router.route(path: ["path", "TO", "fOo"], parameters: params), 42)
    }
    
    func testCaseInsensitiveRouting() throws {
        let route = Route<Int>(path: [.constant("path"), .constant("TO"), .constant("fOo")], output: 42)

        let router = TrieRouter<Int>()
        router.caseInsensitive = true
        router.register(route: route)
        
        let params = Params()
        XCTAssertEqual(router.route(path: ["PATH", "tO", "FOo"], parameters: params), 42)
    }

    func testAnyRouting() throws {
        let route0 = Route<Int>(path: [.constant("a"), .anything], output: 0)
        let route1 = Route<Int>(path: [.constant("b"), .parameter("1"), .anything], output: 1)
        let route2 = Route<Int>(path: [.constant("c"), .parameter("1"), .parameter("2"), .anything], output: 2)
        let route3 = Route<Int>(path: [.constant("d"), .parameter("1"), .parameter("2")], output: 3)
        let route4 = Route<Int>(path: [.constant("e"), .parameter("1"), .anything, .constant("a")], output: 4)

        let router = TrieRouter<Int>()
        router.register(route: route0)
        router.register(route: route1)
        router.register(route: route2)
        router.register(route: route3)
        router.register(route: route4)
        
        XCTAssertEqual(router.route(path: ["a", "b"], parameters: Params()), 0)
        XCTAssertNil(router.route(path: ["a"], parameters: Params()))
        XCTAssertEqual(router.route(path: ["a", "a"], parameters: Params()), 0)
        XCTAssertEqual(router.route(path: ["b", "a", "c"], parameters: Params()), 1)
        XCTAssertNil(router.route(path: ["b"], parameters: Params()))
        XCTAssertNil(router.route(path: ["b", "a"], parameters: Params()))
        XCTAssertEqual(router.route(path: ["b", "a", "c"], parameters: Params()), 1)
        XCTAssertNil(router.route(path: ["c"], parameters: Params()))
        XCTAssertNil(router.route(path: ["c", "a"], parameters: Params()))
        XCTAssertNil(router.route(path: ["c", "b"], parameters: Params()))
        XCTAssertEqual(router.route(path: ["d", "a", "b"], parameters: Params()), 3)
        XCTAssertNil(router.route(path: ["d", "a", "b", "c"], parameters: Params()))
        XCTAssertNil(router.route(path: ["d", "a"], parameters: Params()))
        XCTAssertEqual(router.route(path: ["e", "a", "b", "a"], parameters: Params()), 4)
    }

    func testRouterSuffixes() throws {
        let router = TrieRouter<Int>()
        router.caseInsensitive = true

        let route1 = Route<Int>(path: [.constant("a")], output: 1)
        let route2 = Route<Int>(path: [.constant("aa")], output: 2)
        router.register(route: route1)
        router.register(route: route2)

        let params = Params()
        XCTAssertEqual(router.route(path: ["a"], parameters: params), 1)
        XCTAssertEqual(router.route(path: ["aa"], parameters: params), 2)
    }

    static let allTests = [
        ("testRouter", testRouter),
        ("testCaseInsensitiveRouting", testCaseInsensitiveRouting),
        ("testCaseSensitiveRouting", testCaseSensitiveRouting),
        ("testAnyRouting", testAnyRouting),
        ("testRouterSuffixes", testRouterSuffixes),
    ]
}

final class Params: ParameterContainer {
    var parameters: [ParameterValue] = []
    init() {}
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
