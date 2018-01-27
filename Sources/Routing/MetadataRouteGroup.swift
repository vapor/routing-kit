import HTTP

/// MetadataRouteGroup is similar to the implementation of RouteGroup, instead conforming
/// to MetadataRouteBuilder which allows for routes to be registered with attached metadata

internal final class MetadataRouteGroup: MetadataRouteBuilder {
    let host: String?
    let pathPrefix: [String]
    let middleware: [Middleware]
    let parent: MetadataRouteBuilder
    
    init(host: String?, pathPrefix: [String], middleware: [Middleware], parent: MetadataRouteBuilder) {
        self.host = host
        self.pathPrefix = pathPrefix
        self.middleware = middleware
        self.parent = parent
    }
    
    func register(host: String?, method: Method, path: [String], metadata: [String: Any] = [:], responder: Responder) {
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
        
        parent.register(host: host, method: method, path: path, metadata: metadata, responder: res)
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

