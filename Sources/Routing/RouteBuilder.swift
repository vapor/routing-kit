import HTTP

/// Used to define behavior of objects capable of building routes
public protocol RouteBuilder: class {
    func register(host: String?, method: Method, path: [String], responder: Responder)
}

extension RouteBuilder {
    public func register(method: Method, path: [String], responder: Responder) {
        register(host: nil, method: method, path: path, responder: responder)
    }

    public func register(
        method: Method,
        path: [String],
        responder: @escaping (Request) throws -> ResponseRepresentable
    ) {
        let re = Request.Handler { try responder($0).makeResponse() }
        register(host: nil, method: method, path: path, responder: re)
    }

    public func add(
        _ method: HTTP.Method,
        _ path: String ...,
        _ value: @escaping (HTTP.Request) throws -> HTTP.ResponseRepresentable
    ) {
        let path = path.pathComponents
        let responder = Request.Handler { request in
            return try value(request).makeResponse()
        }

        register(host: nil, method: method, path: path, responder: responder)
    }

}
