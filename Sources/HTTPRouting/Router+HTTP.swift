import Routing
import HTTP

public class Router {
    /// The base branch from which all routing stems outward
    public final let base = Branch<Responder>(name: "", output: nil)

    /// Init
    public init() {}

    /// Register a given path. Use `*` for host OR method to define wildcards that will be matched
    /// if no concrete match exists.
    ///
    /// - parameter host: the host to match, ie: '0.0.0.0', or `*` to match any
    /// - parameter method: the method to match, ie: `GET`, or `*` to match any
    ///     - parameter path: the path that should be registered
    /// - parameter output: the associated output of this path, usually a responder, or `nil`
    public func register(host: String?, method: Method, path: [String], responder: Responder) {
        let host = host ?? "*"
        let path = [host, method.description] + path.filter { !$0.isEmpty }
        base.extend(path, output: responder)
    }


    /// Routes an incoming request
    /// the request will be populated with any found parameters (aka slugs).
    ///
    /// If a handler is found, it is returned.
    public func route(_ request: Request) -> Responder? {
        let path = request.path()
        let result = base.fetch(path)
        request.parameters = result?.slugs(for: path) ?? [:]
        return result?.output
    }
}

extension Request {
    fileprivate func path() -> [String] {
        var host: String = uri.host
        if host.isEmpty { host = "*" }
        let method = self.method.description
        let components = uri.path.pathComponents
        return [host, method] + components
    }
}

extension Router {
    public var routes: [String] {
        return base.routes.map { input in
            var comps = input.pathComponents.makeIterator()
            let host = comps.next() ?? "*"
            let method = comps.next() ?? "*"
            let path = comps.joined(separator: "/")
            return "\(host) \(method) \(path)"
        }
    }
}

public protocol HTTPRouteBuilder: class {
    func register(host: String?, method: Method, path: [String], responder: Responder)
}

extension HTTPRouteBuilder {
    public func register(method: Method, path: [String], responder: Responder) {
        register(host: nil, method: method, path: path, responder: responder)
    }

    public func register(method: Method, path: [String], responder: @escaping (Request) throws -> ResponseRepresentable) {
        let re = Request.Handler { try responder($0).makeResponse() }
        register(host: nil, method: method, path: path, responder: re)
    }
}

extension Router: HTTPRouteBuilder {}

public final class Grouping: HTTPRouteBuilder {
    let host: String?
    let pathPrefix: [String]
    let middleware: [Middleware]
    let parent: HTTPRouteBuilder

    public init(host: String?, pathPrefix: [String], middleware: [Middleware], parent: HTTPRouteBuilder) {
        self.host = host
        self.pathPrefix = pathPrefix
        self.middleware = middleware
        self.parent = parent
    }

    public func register(host: String?, method: Method, path: [String], responder: Responder) {
        let host = host ?? self.host
        let path = self.pathPrefix + path

        let res: Responder
        if middleware.isEmpty {
            res = responder
        } else {
            let middleware = self.middleware
            res = Request.Handler { request in
                return try middleware.chain(to: responder).respond(to: request)
            }
        }

        parent.register(host: host, method: method, path: path, responder: res)
    }
}

extension HTTPRouteBuilder {
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

    public func grouped(host: String) -> HTTPRouteBuilder {
        return Grouping(host: host, pathPrefix: [], middleware: [], parent: self)
    }

    public func grouped(_ path: String...) -> HTTPRouteBuilder {
        return grouped(path)
    }

    public func grouped(_ path: [String]) -> HTTPRouteBuilder {
        let components = path.pathComponents
        return Grouping(host: nil, pathPrefix: components, middleware: [], parent: self)
    }

    public func grouped(middleware: Middleware...) -> HTTPRouteBuilder {
        return grouped(middleware: middleware)
    }

    // TODO: External arg necessary on middleware groups?
    public func grouped(middleware: [Middleware]) -> HTTPRouteBuilder {
        return Grouping(host: nil, pathPrefix: [], middleware: middleware, parent: self)
    }

    // MARK: Closures

    public func group(host: String, handler: (HTTPRouteBuilder) -> ()) {
        let builder = grouped(host: host)
        handler(builder)
    }

    public func group(_ path: String ..., handler: (HTTPRouteBuilder) -> ()) {
        group(path: path, handler: handler)
    }

    public func group(path: [String], handler: (HTTPRouteBuilder) -> ()) {
        let path = path.pathComponents
        let builder = grouped(path)
        handler(builder)
    }

    public func group(_ middleware: Middleware..., handler: (HTTPRouteBuilder) -> ()) {
        group(middleware: middleware, handler: handler)
    }

    public func group(middleware: [Middleware], handler: (HTTPRouteBuilder) -> ()) {
        let builder = grouped(middleware: middleware)
        handler(builder)
    }
}



extension Middleware {
    fileprivate func chain(to responder: Responder) -> Responder {
        return Request.Handler { request in
            return try self.respond(to: request, chainingTo: responder)
        }
    }
}

extension Collection where Iterator.Element == Middleware {
    fileprivate func chain(to responder: Responder) -> Responder {
        return reversed().reduce(responder) { nextResponder, nextMiddleware in
            return Request.Handler { request in
                return try nextMiddleware.respond(to: request, chainingTo: nextResponder)
            }
        }
    }
}
