import Branches
import Foundation
import HTTP

public class Router {
    /// The base branch from which all routing stems outward
    public final let base = Branch<Responder>(name: "", output: nil)
    
    /// A collection of all routes that have been registered with the Router
    /// and their associated metadata, if any
    public var routeMetadata: [Route] = []
    
    /// Init
    public init() {}
    
    /// Register a given path. Use `*` for host OR method to define wildcards that will be matched
    /// if no concrete match exists.
    ///
    /// - parameter host: the host to match, ie: '0.0.0.0', or `*` to match any
    /// - parameter method: the method to match, ie: `GET`, or `*` to match any
    ///     - parameter path: the path that should be registered
    /// - parameter output: the associated output of this path, usually a responder, or `nil`
    public func register(host: String?, method: HTTP.Method, path: [String], responder: Responder) {
        let host = host ?? "*"
        let path = path.filter{ !$0.isEmpty }
        
        // Registers `route` metadata
        let route = Route(host: host, components: path, method: method)
        routeMetadata.append(route)
        
        let fullPath = [host, method.description] + path
        base.extend(fullPath, output: responder)
    }
    
    public func register(
        host: String?,
        method: HTTP.Method,
        path: [String],
        metadata: [String: Any],
        responder: Responder
        ) {
        let host = host ?? "*"
        let path = path.filter{ !$0.isEmpty }
        
        // Registers `route` metadata
        let route = Route(host: host, components: path, method: method, metadata: metadata)
        routeMetadata.append(route)
        
        let fullPath = [host, method.description] + path
        base.extend(fullPath, output: responder)
    }
    
    // caches static route resolutions
    private var _cache: [String: Responder?] = [:]
    private var _cacheLock = NSLock()
    
    /// Removes all entries from this router's cache.
    ///
    public func flushCache() {
        _cacheLock.lock()
        _cache.removeAll()
        _cacheLock.unlock()
    }
    
    /// Removes the cached Responder for a given Request.
    /// If there is no cached Responder, returns nil.
    ///
    /// NOTE: If you do not register a new Responder for the
    /// Request, the old Responder will be invoked on a subsequent
    /// Request and re-cached. I.e. this function does not prune
    /// the Branch.
    @discardableResult
    public func flushCache(for request: Request) -> Responder? {
        _cacheLock.lock()
        let maybeCached = _cache.removeValue(forKey: request.routeKey)
        _cacheLock.unlock()
        
        if let cached = maybeCached {
            return cached
        } else {
            return nil
        }
    }
    
    /// Routes an incoming request
    /// the request will be populated with any found parameters (aka slugs).
    ///
    /// If a handler is found, it is returned.
    public func route(_ request: Request) -> Responder? {
        let key = request.routeKey
        
        // check the static route cache
        
        _cacheLock.lock()
        let maybeCached = _cache[key]
        _cacheLock.unlock()
        
        if let cached = maybeCached {
            return cached
        }
        
        let path = request.path()
        let result = base.fetch(path)
        
        request.parameters = result?.slugs(for: path) ?? [:]
        
        // if there are no dynamic slugs, we can cache
        if request.parameters.object?.isEmpty == true {
            _cacheLock.lock()
            _cache[key] = result?.output
            _cacheLock.unlock()
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

