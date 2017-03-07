import HTTP

public typealias RequestHandler = (Request) throws -> ResponseRepresentable

/// Used to define behavior of objects capable of building routes
public protocol RouteBuilder: class {
    func register(host: String?, method: Method, path: [String], responder: Responder)
}

extension RouteBuilder {
    public func register(
        host: String? = nil,
        method: Method = .get,
        path: [String] = [],
        responder: @escaping RequestHandler
    ) {
        let re = Request.Handler { try responder($0).makeResponse() }
        let path = path.pathComponents
        register(host: host, method: method, path: path, responder: re)
    }

    public func register(method: Method = .get, path: [String] = [], responder: Responder) {
        let path = path.pathComponents
        register(host: nil, method: method, path: path, responder: responder)
    }

    // FIXME: This function feels like it might not fit
    public func add(
        _ method: HTTP.Method,
        _ path: String ...,
        _ value: @escaping RequestHandler
    ) {
        let responder = Request.Handler { try value($0).makeResponse() }
        register(method: method, path: path, responder: responder)
    }

}
