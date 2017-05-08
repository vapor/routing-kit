import XCTest

import HTTP
import Routing

class RouteBuilderTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testVariadic", testVariadic),
        ("testMoreThanThreeArgs", testMoreThanThreeArgs),
        ("testCustomMethod", testCustomMethod),
        ("testAll", testAll),
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
        let bytes = try request.bytes(running: builder.router)
        
        XCTAssertEqual(bytes, "Please don't read this".makeBytes())
    }
    
    func testCustomMethod() throws {
        let builder = Dropped()
        builder.add(.other(method: "custom"), "custom", "method") { _ in
            return "Custom method"
        }
        
        let request = Request(method: .other(method: "custom"), path: "custom/method")
        let bytes = try request.bytes(running: builder.router)
        
        XCTAssertEqual(bytes, "Custom method".makeBytes())
    }
    
    func testAll() throws {
        let builder = Dropped()
        builder.all("all", "methods") { _ in
            return "All around the world (repeat 144)"
        }
        
        let methods: [HTTP.Method] = [
            .delete, .get, .head, .post, .put, .connect, .options, .trace, .patch, .other(method: "other")
        ]
        
        methods.forEach {
            let request = Request(method: $0, path: "all/methods")
            
            do {
                let bytes = try request.bytes(running: builder.router)
                XCTAssertEqual(bytes, "All around the world (repeat 144)".makeBytes())
            } catch {
                XCTFail("Routing failed: \(error) for method: \($0)")
            }
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
