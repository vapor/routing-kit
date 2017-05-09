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
    
    // caches static route resolutions
    private var _cache: [String: Responder?] = [:]

    /// Routes an incoming request
    /// the request will be populated with any found parameters (aka slugs).
    ///
    /// If a handler is found, it is returned.
    public func route(_ request: Request) -> Responder? {
        let key = request.routeKey
        
        // check the static route cache
        if let cached = _cache[key] {
            return cached
        }
        
        let path = request.path()
        let result = base.fetch(path)

        request.parameters = result?.slugs(for: path) ?? [:]
        
        // if there are no dynamic slugs, we can cache
        if request.parameters.object?.isEmpty == true {
            _cache[key] = result?.output
        }
        
        return result?.output
    }
}

extension Branch {
    /// It is not uncommon to place slugs along our branches representing keys that will
    /// match for the path given. When this happens, the path can be laid across here to extract
    /// slug values efficiently.
    ///
    /// Branches: `path/to/:name`
    /// Given Path: `path/to/joe`
    ///
    /// let slugs = branch.slugs(for: givenPath) // ["name": "joe"]
    public func slugs(for path: [String]) -> Parameters {
        var slugs: [String: Parameters] = [:]
        slugIndexes.forEach { key, index in
            guard let val = path[safe: index]
                .flatMap({ $0.removingPercentEncoding })
                .flatMap({ Parameters.string($0) })
                else { return }

            if let existing = slugs[key] {
                var array = existing.array ?? [existing]
                array.append(val)
                slugs[key] = .array(array)
            } else {
                slugs[key] = val
            }
        }
        return .object(slugs)
    }
}


extension Request {
    // unique routing key for this request
    fileprivate var routeKey: String {
        return uri.hostname
            + ";" + method.description
            + ";" + uri.path
    }
    
    fileprivate func path() -> [String] {
        var host: String = uri.hostname
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
