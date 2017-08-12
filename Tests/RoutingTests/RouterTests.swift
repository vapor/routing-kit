import XCTest
import HTTP
import Branches
import Routing
import URI

extension String: Swift.Error {}

class RouterTests: XCTestCase {
    static let allTests = [
        ("testRouter", testRouter),
        ("testWildcardMethod", testWildcardMethod),
        ("testWildcardHost", testWildcardHost),
        ("testHostMatch", testHostMatch),
        ("testMiss", testMiss),
        ("testWildcardPath", testWildcardPath),
        ("testParameters", testParameters),
        ("testEmpty", testEmpty),
        ("testNoHostWildcard", testNoHostWildcard),
        ("testRouterDualSlugRoutes", testRouterDualSlugRoutes),
        ("testRouteLogs", testRouteLogs),
        ("testRouterThrows", testRouterThrows),
        ("testParams", testParams),
        ("testOutOfBoundsParams", testOutOfBoundsParams),
        ("testParamsDuplicateKey", testParamsDuplicateKey),
    ]

    func testRouter() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .get, path: ["hello"]) { request in
            return Response(status: .ok, body: "Hello, World!")
        }

        let request = Request(method: .get, uri: "http://0.0.0.0/hello")
        let response = try router.respond(to: request)
        XCTAssert(response.body.bytes?.makeString() == "Hello, World!")
    }

    func testWildcardMethod() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .wildcard, path: ["hello"]) { request in
            return Response(status: .ok, body: "Hello, World!")
        }

        let method: [HTTP.Method] = [.get, .post, .put, .patch, .delete, .trace, .head, .options]
        try method.forEach { method in
            let request = Request(method: method, uri: "http://0.0.0.0/hello")
            let response = try router.respond(to: request)
            XCTAssertEqual(response.body.bytes?.makeString(), "Hello, World!")
        }
    }

    func testWildcardHost() throws {
        let router = Router()
        router.register(host: "*", method: .get, path: ["hello"]) { request in
            return Response(status: .ok, body: "Hello, World!")
        }

        let hosts: [String] = ["0.0.0.0", "chat.app.com", "[255.255.255.255.255]", "slack.app.com"]
        try hosts.forEach { host in
            let request = Request(method: .get, uri: "http://\(host)/hello")
            let response = try router.respond(to: request)
            XCTAssertEqual(response.body.bytes?.makeString(), "Hello, World!")
        }
    }

    func testHostMatch() throws {
        let router = Router()

        let hosts: [String] = ["0.0.0.0", "chat.app.com", "255.255.255.255", "slack.app.com"]
        hosts.forEach { host in
            router.register(host: host, path: ["hello"]) { request in
                return Response(status: .ok, body: "Host: \(host)")
            }
        }

        try hosts.forEach { host in
            let request = Request(method: .get, uri: "http://\(host)/hello")
            let response = try router.respond(to: request)
            XCTAssert(response.body.bytes?.makeString() == "Host: \(host)")
        }
    }

    func testMiss() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .get, path: ["hello"]) { request in
            XCTFail("should not be found, wrong host")
            return "[fail]"
        }

        let request = Request(method: .get, uri: "http://[255.255.255.255.255]/hello")
        let handler = router.route(request)
        XCTAssert(handler == nil)
    }

    func testWildcardPath() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .get, path: ["hello", "*"]) { request in
            return "Hello, World!"
        }

        let paths: [String] = [
            "hello",
            "hello/zero",
            "hello/extended/path",
            "hello/very/extended/path.pdf"
        ]

        try paths.forEach { path in
            let request = Request(method: .get, uri: "http://0.0.0.0/\(path)")
            let response = try router.respond(to: request)
            XCTAssert(response.body.bytes?.makeString() == "Hello, World!")
        }
    }

    func testParameters() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .get, path: ["hello", ":name", ":age"]) { request in
            guard let name = request.parameters["name"]?.first else { throw "missing param: name" }
            guard let age = request.parameters["age"]?.first else { throw "missing or invalid param: age" }
            return "Hello, \(name) aged \(age)."
        }

        let namesAndAges: [(String, Int)] = [
            ("a", 12),
            ("b", 42),
            ("c", 200),
            ("d", 1)
        ]

        try namesAndAges.forEach { name, age in
            let request = Request(method: .get, uri: "http://0.0.0.0/hello/\(name)/\(age)")
            let response = try router.respond(to: request)
            XCTAssertEqual(response.body.bytes?.makeString(), "Hello, \(name) aged \(age).")
        }
    }

    func testEmpty() throws {
        let router = Router()
        router.register(path: []) { request in
            return Response(status: .ok, body: "Hello, Empty!")
        }

        let empties: [String] = ["", "/"]
        try empties.forEach { emptypath in
            let uri = URI(scheme: "http", hostname: "0.0.0.0", path: emptypath)
            let request = Request(method: .get, uri: uri)
            let response = try router.respond(to: request)
            XCTAssertEqual(response.body.bytes?.makeString(), "Hello, Empty!")
        }
    }

    func testNoHostWildcard() throws {
        let router = Router()
        router.register { request in
            return Response(status: .ok, body: "Hello, World!")
        }

        let uri = URI(
            scheme: "",
            hostname: ""
        )
        let request = Request(method: .get, uri: uri)
        let response = try router.respond(to: request)
        XCTAssertEqual(response.body.bytes?.makeString(), "Hello, World!")
    }

    func testRouterDualSlugRoutes() throws {
        let router = Router()
        router.register(path: ["foo", ":a", "one"]) { _ in return "1" }
        router.register(path: ["foo", ":b", "two"]) { _ in return "2" }

        let requestOne = Request(method: .get, path: "foo/slug-val/one")
        let responseOne = try router.respond(to: requestOne)
        XCTAssertEqual(responseOne.body.bytes?.makeString(), "1")

        let requestTwo = Request(method: .get, path: "foo/slug-val/two")
        let responseTwo = try router.respond(to: requestTwo)
        XCTAssertEqual(responseTwo.body.bytes?.makeString(), "2")    }

    func testRouteLogs() throws {
        let router = Router()
        let responder = Request.Handler { _ in return Response(status: .ok) }
        router.register(path: ["foo", "bar", ":id"], responder: responder)
        router.register(path: ["foo", "bar", ":id", "zee"], responder: responder)
        router.register(path: ["1/2/3/4/5/6/7"], responder: responder)
        router.register(method: .post, path: ["multi-path"], responder: responder)
        router.register(method: .put, path: ["multi-path"], responder: responder)

        let expectation = [
            "* POST multi-path",
            "* PUT multi-path",
            "* GET 1/2/3/4/5/6/7",
            "* GET foo/bar/:id",
            "* GET foo/bar/:id/zee"
        ]

        XCTAssertEqual(Set(router.routes), Set(expectation))
    }

    func testRouterThrows() {
        let router = Router()

        do {
            let request = Request(method: .get, path: "asfd")
            _ = try router.respond(to: request)
            XCTFail("Should throw missing route")
        } catch {
            print(error)
        }
    }


    func testParams() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend([":a", ":b", ":c", "*"], output: "abc")
        let path = ["zero", "one", "two", "d", "e", "f"]
        guard let result = base.fetch(path) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        let params = result.slugs(for: path)
        XCTAssert(params["a"]?.first == "zero")
        XCTAssert(params["b"]?.first == "one")
        XCTAssert(params["c"]?.first == "two")
        XCTAssert(result.output == "abc")
    }

    func testOutOfBoundsParams() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend([":a", ":b", ":c", "*"], output: "abc")
        let path = ["zero", "one", "two", "d", "e", "f"]
        guard let result = base.fetch(path) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        let params = result.slugs(for: ["zero", "one"])
        XCTAssert(params["a"]?.first == "zero")
        XCTAssert(params["b"]?.first == "one")
        XCTAssert(params["c"]?.first == nil)
        XCTAssert(result.output == "abc")
    }

    func testParamsDuplicateKey() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend([":a", ":a", ":a", "*"], output: "abc")
        let path = ["zero", "one", "two", "d", "e", "f"]
        guard let result = base.fetch(path) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        let params = result.slugs(for: ["zero", "one"])
        XCTAssert(params["a"]?[0] == "zero")
        XCTAssert(params["a"]?[1] == "one")
        XCTAssert(params["a"]?[safe: 2] == nil)
        XCTAssert(result.output == "abc")
    }

    func testParameterizable() throws {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend([Foo.parameter, Foo.parameter, Foo.parameter, "*"], output: "abc")
        let path = ["zero", "one", "two", "d", "e", "f"]
        guard let result = base.fetch(path) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        var params = result.slugs(for: ["zero", "one"])
        let one = try params.next(Foo.self)
        let two = try params.next(Foo.self)
        XCTAssert(one.id == "zero")
        XCTAssert(two.id == "one")
    }
}

struct Foo {
    let id: String
}

extension Foo: Parameterizable {
    static let uniqueSlug = "foo-slug"

    static func make(for parameter: String) throws -> Foo {
        return  .init(id: parameter)
    }
}
