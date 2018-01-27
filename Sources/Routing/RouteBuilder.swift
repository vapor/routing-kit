import HTTP
import WebSockets

public typealias RouteHandler = (Request) throws -> ResponseRepresentable
public typealias WebSocketRouteHandler = (Request, WebSocket) throws -> Void

/// Used to define behavior of objects capable of building routes
public protocol RouteBuilder: class {
    func register(host: String?, method: Method, path: [String], metadata: [String: String]?, responder: Responder)
}

extension RouteBuilder {
    public func register(
        host: String? = nil,
        method: Method = .get,
        path: [String] = [],
        metadata: [String: String]? = nil,
        responder: @escaping RouteHandler
    ) {
        let re = Request.Handler { try responder($0).makeResponse() }
        let path = path.pathComponents
        register(host: host, method: method, path: path, metadata: metadata, responder: re)
    }

    public func register(method: Method = .get, path: [String] = [], metadata: [String: String]? = nil, responder: Responder) {
        let path = path.pathComponents
        register(host: nil, method: method, path: path, metadata: metadata, responder: responder)
    }

}

extension RouteBuilder {
    #if swift(>=4)
    public func add(
        _ method: HTTP.Method,
        _ path: String ...,
        metadata: [String: String]? = nil,
        value: @escaping RouteHandler
    ) {
        let responder = Request.Handler { try value($0).makeResponse() }
        register(method: method, path: path, metadata: metadata, responder: responder)
    }
    #else
    public func add(
        _ method: HTTP.Method,
        _ path: String ...,
        _ metadata: [String: String]? = nil,
        _ value: @escaping RouteHandler
    ) {
        let responder = Request.Handler { try value($0).makeResponse() }
        register(method: method, path: path, metadata: metadata, responder: responder)
    }
    #endif
    
    public func socket(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping WebSocketRouteHandler) {
        register(method: .get, path: segments, metadata: metadata) { req in
            return try req.upgradeToWebSocket {
                try handler(req, $0)
            }
        }
    }
    
    public func all(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .other(method: "*"), path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
    
    public func get(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .get, path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
    
    public func post(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .post, path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
    
    public func put(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .put, path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
    
    public func patch(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .patch, path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
    
    public func delete(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .delete, path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
    
    public func options(_ segments: String..., metadata: [String: String]? = nil, handler: @escaping RouteHandler) {
        register(method: .options, path: segments, metadata: metadata) {
            try handler($0).makeResponse()
        }
    }
}
