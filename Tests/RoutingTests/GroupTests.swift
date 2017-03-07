import XCTest
import HTTP
import Routing

class GroupTests: XCTestCase {
    static var allTests = [
        ("testBasic", testBasic),
        ("testVariadic", testVariadic),
        ("testHost", testHost),
        ("testHostMiss", testHostMiss),
        ("testMiddleware", testMiddleware),
    ]

    func testBasic() throws {
        let router = Router()

        router.group("users") { users in
            users.add(.get, ":id") { request in
                return "show"
            }
        }

        let request = Request(method: .get, path: "users/5")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes, "show".makeBytes())
        XCTAssertEqual(request.parameters["id"], "5")
    }

    func testVariadic() throws {
        let router = Router()

        router.group("users", "devices", "etc") { users in
            users.add(.get, ":id") { request in
                return "show"
            }
        }
        let request = Request(method: .get, path: "users/devices/etc/5")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes, "show".makeBytes())
        XCTAssertEqual(request.parameters["id"], "5")
    }

    func testHost() throws {
        let router = Router()

        router.group(host: "192.168.0.1") { host in
            host.add(.get, "host-only") { request in
                return "host"
            }
        }
        router.add(.get, "host-only") { req in
            return "nothost"
        }

        let request = Request(method: .get, path: "host-only", host: "192.168.0.1")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes, "host".makeBytes())
    }

    func testHostMiss() throws {
        let router = Router()

        router.group(host: "192.168.0.1") { host in
            host.add(.get, "host-only") { request in
                return "host"
            }
        }
        router.add(.get, "host-only") { req in
            return "nothost"
        }

        let request = Request(method: .get, path: "host-only", host: "BADHOST")
        let bytes = try request.bytes(running: router)

        XCTAssertEqual(bytes, "nothost".makeBytes())
    }

    func testMiddleware() throws {
        class Middy: Middleware {
            func respond(to request: Request, chainingTo next: Responder) throws -> Response {
                request.storage["middleware"] = true
                return try next.respond(to: request)
            }
        }

        let router = Router()
        router.group(Middy()) { builder in
            builder.register { _ in return "hello" }
        }

        let request = Request(method: .get, path: "/")
        XCTAssertNil(request.storage["middleware"])
        let response = try router.respond(to: request)
        let middleware = request.storage["middleware"] as? Bool
        XCTAssertEqual(middleware, true)
        XCTAssertEqual(response.body.bytes?.string, "hello")
    }
}
