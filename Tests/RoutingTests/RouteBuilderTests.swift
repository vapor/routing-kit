import XCTest

import HTTP
import Routing

class RouteBuilderTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testVariadic", testVariadic),
        ("testMoreThanThreeArgs", testMoreThanThreeArgs),
    ]
    
    func testBasic() throws {
        let builder = Dropped()
        builder.get("hello") { _ in
            return "world!"
        }
        
        let request = Request(method: .get, path: "hello")
        let bytes = try request.bytes(running: builder.router)
        
        XCTAssertEqual(bytes, "world!".makeBytes())
    }
    
    func testVariadic() throws {
        let builder = Dropped()
        builder.delete("foo", "bar", "baz") { _ in
            return "1337"
        }
        
        let request = Request(method: .delete, path: "foo/bar/baz")
        let bytes = try request.bytes(running: builder.router)
        
        XCTAssertEqual(bytes, "1337".makeBytes())
    }
    
    func testMoreThanThreeArgs() throws {
        let builder = Dropped()
        builder.post(":userId", "messages", ":messageId", "read") { _ in
            return "Please don't read this"
        }
        
        let request = Request(method: .post, path: "1/messages/10/read")
        do {
            let bytes = try request.bytes(running: builder.router)
            XCTAssertEqual(bytes, "Please don't read this".makeBytes())
        } catch {
            XCTFail("Routing failed: \(error)")
        }
        
    }
}

/// A mock for RouteBuilder
final class Dropped: RouteBuilder {
    let router = Router()
    
    public func register(host: String?, method: HTTP.Method, path: [String], responder: Responder) {
        router.register(host: host, method: method, path: path, responder: responder)
    }
}
