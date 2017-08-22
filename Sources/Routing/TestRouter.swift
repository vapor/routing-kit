import Core
import HTTP

/// FIXME: just for testing
public final class TestRouter: SyncRouter, AsyncRouter {
    var storage: [String: Responder]
    
    public init() {
        storage = [:]
    }
    
    public func register(responder: Responder, at path: [PathComponent]) {
        let path = path.flatMap {
            switch $0 {
            case .constant(let s):
                return s
            case .parameter(let p):
                return ":" + p.uniqueSlug
            }
            }.joined(separator: "/")
        storage[path] = responder
    }
    
    public func route(path: [String], parameters: inout ParameterBag) -> Responder? {
        guard let responder = storage[path.joined(separator: "/")] else {
            return nil
        }
        
        return responder
    }
}

// FIXME: just for testing
// TODO: needs to take into account the middleware
public struct RouterResponder: Responder {
    let router: Router
    public init(router: Router) {
        self.router = router
    }
    
    public func respond(to req: Request) throws -> Future<Response> {
        guard let responder = router.route(request: req) else {
            // TODO: needs to return the error page
            let promise = Promise<Response>()
            
            try promise.complete(Response(status: .notFound))
            
            return promise.future
        }
        
        return try responder.respond(to: req)
    }
}

