import Branches
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

extension Router: RouteBuilder {}

// FIXME: Swift.Debuggable
public enum RouterError: Swift.Error {
    case missingRoute(for: Request)
}

extension Router: Responder {
    public func respond(to request: Request) throws -> Response {
        guard let responder = route(request) else { throw RouterError.missingRoute(for: request) }
        return try responder.respond(to: request)
    }
}
