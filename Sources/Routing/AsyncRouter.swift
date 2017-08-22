import Core
import HTTP

/// Capable of register async routes.
public protocol AsyncRouter: Router { }

extension AsyncRouter {
    /// Registers a route handler at the supplied path.
    public func on(_ method: Method, to path: PathComponentRepresentable..., use closure: @escaping BasicAsyncResponder.Closure) {
        let responder = BasicAsyncResponder(closure: closure)
        self.register(
            responder: responder,
            at: [.constant(method.string)] + path.makePathComponents()
        )
    }
}

/// A basic, closure-based responder.
public struct BasicAsyncResponder: Responder {
    /// Responder closure
    public typealias Closure = (Request) throws -> Future<ResponseRepresentable>

    /// The stored responder closure.
    public let closure: Closure

    /// Create a new basic responder.
    public init(closure: @escaping Closure) {
        self.closure = closure
    }

    /// See: HTTP.Responder.respond
    public func respond(to req: Request) throws -> Future<Response> {
        let promise = Promise<Response>()

        try closure(req).then { res in
            do {
                let res = try res.makeResponse()
                try promise.complete(res)
            } catch {
                // FIXME: what do we do w/ the error here?
                try? promise.complete(error)
            }
        }


        return promise.future
    }
}
