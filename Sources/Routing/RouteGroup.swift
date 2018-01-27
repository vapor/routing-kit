import HTTP

/// RouteGroup is a step in the RouteBuilder chain that
/// allows users to collect metadata about various endpoints
///
/// for example, if we have several routes that begin with "some/prefix/path"
/// we might want to group those together so that we can easily append
internal final class RouteGroup: RouteBuilder {
    let host: String?
    let pathPrefix: [String]
    let middleware: [Middleware]
    let parent: RouteBuilder

    init(host: String?, pathPrefix: [String], middleware: [Middleware], parent: RouteBuilder) {
        self.host = host
        self.pathPrefix = pathPrefix
        self.middleware = middleware
        self.parent = parent
    }

    func register(
        host: String?,
        method: Method,
        path: [String],
        metadata: [String: String]? = nil,
        responder: Responder
    ) {
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
