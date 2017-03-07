import XCTest
import HTTP
import Routing

class GroupedTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testVariadic", testVariadic),
        ("testHost", testHost),
        ("testChained", testChained),
        ("testMultiChained", testMultiChained),
    ]

    func testBasic() throws {
        let router = Router()

        let users = router.grouped("users")
        users.register(method: .get, path: [":id"]) { request in
            return "show"
        }

        let request = Request(method: .get, path: "users/5")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes.string, "show")
        XCTAssertEqual(request.parameters["id"], "5")
    }

    func testVariadic() throws {
        let router = Router()

        let users = router.grouped("users", "devices", "etc")
        users.add(.get, ":id") { request in
            return "show"
        }

        let request = Request(method: .get, path: "users/devices/etc/5")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes, "show".makeBytes())
        XCTAssertEqual(request.parameters["id"], "5")
    }

    func testHost() throws {
        let router = Router()
        let host = router.grouped(host: "192.168.0.1")
        host.register(method: .get, path: ["host-only"]) { request in
            return "host group found"
        }

        router.register(method: .get, path: ["host-only"]) { _ in return "nothost" }
        let request = Request(method: .get, path: "host-only", host: "192.168.0.1")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes.string, "host group found")
    }

    func testChained() throws {
        let router = Router()

        let users = router.grouped("users", "devices", "etc").grouped("even", "deeper")
        users.add(.get, ":id") { request in
            return "show"
        }

        let request = Request(method: .get, path: "users/devices/etc/even/deeper/5")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes.string, "show")
        XCTAssertEqual(request.parameters["id"], "5")
    }

    func testMultiChained() throws {
        class Middy: Middleware {
            func respond(to request: Request, chainingTo next: Responder) throws -> Response {
                request.storage["middleware"] = true
                return try next.respond(to: request)
            }
        }

        let router = Router()
        let builder = router.grouped("a", "path").grouped(Middy()).grouped(host: "9.9.9.9")
        builder.add(.get, "/") { req in
            return "got it"
        }

        let request = Request(method: .get, path: "a/path", host: "9.9.9.9")
        let responder = router.route(request)
        let response = try responder?.respond(to: request)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.body.bytes?.string, "got it")
        let middleware = request.storage["middleware"] as? Bool
        XCTAssertEqual(middleware, true)

        let bad = Request(method: .get, path: "a/path", host: "0.0.0.0")
        XCTAssertNil(router.route(bad))
    }
}
