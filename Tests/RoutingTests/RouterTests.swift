import Async
import Dispatch
import Bits
import Routing
import Service
import XCTest

extension PathComponent {
    static func string(_ string: String) -> PathComponent {
        return .init(string: string)
    }
}

class RouterTests: XCTestCase {
    func testRouter() throws {
        let router = TrieRouter<Int>()

        let path: [PathComponent] = [.string("foo"), .string("bar"), .string("baz")]

        let route = Route<Int>(
            path: path.map { .constant($0) } + [.parameter(.string(User.uniqueSlug))],
            output: 42
        )
        router.register(route: route)

        let container = BasicContainer(
            config: Config(),
            environment: .development,
            services: Services(),
            on: EmbeddedEventLoop()
        )
        let params = Params()
        XCTAssertEqual(router.route(path: path + [.string("Tanner")], parameters: params), 42)
        try XCTAssertEqual(params.parameter(User.self, using: container).wait().name, "Tanner")
    }
    
    func testCaseSensitiveRouting() throws {
        let router = TrieRouter<Int>()
        
        let path: [PathComponent] = [.string("path"), .string("TO"), .string("fOo")]
        
        let route = Route<Int>(
            path: path.map { .constant($0) },
            output: 42
        )
        router.register(route: route)
        
        let params = Params()
        XCTAssertEqual(router.route(path: [.string("PATH"), .string("tO"), .string("FOo")], parameters: params), nil)
        XCTAssertEqual(router.route(path: [.string("path"), .string("TO"), .string("fOo")], parameters: params), 42)
    }
    
    func testCaseInsensitiveRouting() throws {
        let router = TrieRouter<Int>()
        router.caseInsensitive = true
        
        let path: [PathComponent] = [.string("path"), .string("TO"), .string("fOo")]
        
        let route = Route<Int>(path: path.map { .constant($0) }, output: 42)
        router.register(route: route)
        
        let params = Params()
        XCTAssertEqual(router.route(path: [.string("PATH"), .string("tO"), .string("FOo")], parameters: params), 42)
    }

    func testAnyRouting() throws {
        let router = TrieRouter<Int>()
        
        let route0 = Route<Int>(path: [
            .constant(.string("a")),
            .anything
        ], output: 0)
        
        let route1 = Route<Int>(path: [
            .constant(.string("b")),
            .parameter(.string("1")),
            .anything
        ], output: 1)
        
        let route2 = Route<Int>(path: [
            .constant(.string("c")),
            .parameter(.string("1")),
            .parameter(.string("2")),
            .anything
        ], output: 2)
        
        let route3 = Route<Int>(path: [
            .constant(.string("d")),
            .parameter(.string("1")),
            .parameter(.string("2")),
        ], output: 3)
        
        let route4 = Route<Int>(path: [
            .constant(.string("e")),
            .parameter(.string("1")),
            .anything,
            .constant(.string("a"))
        ], output: 4)
        
        router.register(route: route0)
        router.register(route: route1)
        router.register(route: route2)
        router.register(route: route3)
        router.register(route: route4)
        
        XCTAssertEqual(
            router.route(path: [.string("a"), .string("b")], parameters: Params()),
            0
        )
        
        XCTAssertNil(router.route(path: [.string("a")], parameters: Params()))
        
        XCTAssertEqual(
            router.route(path: [.string("a"), .string("a")], parameters: Params()),
            0
        )
        
        XCTAssertEqual(
            router.route(path: [.string("b"), .string("a"), .string("c")], parameters: Params()),
            1
        )
        
        XCTAssertNil(router.route(path: [.string("b")], parameters: Params()))
        XCTAssertNil(router.route(path: [.string("b"), .string("a")], parameters: Params()))
        
        XCTAssertEqual(
            router.route(path: [.string("b"), .string("a"), .string("c")], parameters: Params()),
            1
        )
        
        XCTAssertNil(router.route(path: [.string("c")], parameters: Params()))
        XCTAssertNil(router.route(path: [.string("c"), .string("a")], parameters: Params()))
        XCTAssertNil(router.route(path: [.string("c"), .string("b")], parameters: Params()))
        
        XCTAssertEqual(
            router.route(path: [.string("d"), .string("a"), .string("b")], parameters: Params()),
            3
        )
        
        XCTAssertNil(router.route(path: [.string("d"), .string("a"), .string("b"), .string("c")], parameters: Params()))
        XCTAssertNil(router.route(path: [.string("d"), .string("a")], parameters: Params()))
        
        XCTAssertEqual(
            router.route(path: [.string("e"), .string("a"), .string("b"), .string("a")], parameters: Params()),
            4
        )
    }

    func testRouterSuffixes() throws {
        let router = TrieRouter<Int>()
        router.caseInsensitive = true

        let path1: PathComponent = .string("a")
        let path2: PathComponent = .string("aa")
        let route1 = Route<Int>(path: [.constant(path1)], output: 1)
        let route2 = Route<Int>(path: [.constant(path2)], output: 2)
        router.register(route: route1)
        router.register(route: route2)

        let params = Params()
        XCTAssertEqual(router.route(path: [.string("a")], parameters: params), 1)
        XCTAssertEqual(router.route(path: [.string("aa")], parameters: params), 2)
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
    var parameters: Parameters = []
    init() {}
}

final class User: Parameter {
    var name: String

    init(name: String) {
        self.name = name
    }

    static func make(for parameter: String, using container: Container) throws -> Future<User> {
        return Future.map(on: container) { User(name: parameter) }
    }
}
