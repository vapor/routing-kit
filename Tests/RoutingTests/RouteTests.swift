import HTTP
import Routing
import URI
import XCTest

class RouteTests: XCTestCase {
    func testRoute() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .get, path: ["hello"]) { req in
            return Response(status: .ok, body: "HI")
        }

        let request = Request(method: .get, uri: "http://0.0.0.0/hello")
        let response = try router.respond(to: request)
        XCTAssertEqual(response.body.bytes?.makeString(), "HI")
    }

    func testRouteParams() throws {
        let router = Router()
        router.register(host: "0.0.0.0", method: .get, path: [":zero", ":one", ":two", "*"]) { req in
            let zero = req.parameters.data["zero"]?.first ?? "[fail]"
            let one = req.parameters.data["one"]?.first ?? "[fail]"
            let two = req.parameters.data["two"]?.first ?? "[fail]"
            return Response(status: .ok, body: "\(zero):\(one):\(two)")
        }

        let paths: [[String]] = [
            ["a", "b", "c"],
            ["1", "2", "3", "4"],
            ["x", "y", "z", "should", "be", "in", "wildcard"]
        ]
        try paths.forEach { path in
            let uri = URI(
                scheme: "http",
                userInfo: nil,
                hostname: "0.0.0.0",
                port: 80,
                path: path.joined(separator: "/"),
                query: nil,
                fragment: nil
            )
            let request = Request(method: .get, uri: uri)
            let response = try router.respond(to: request)
            XCTAssertEqual(response.body.bytes?.makeString(), path.prefix(3).joined(separator: ":"))
        }
    }


    static let allTests = [
        ("testRoute", testRoute),
        ("testRouteParams", testRouteParams),
    ]
}
