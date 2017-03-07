import HTTP
import Debugging

extension Router: Responder {
    public func respond(to request: Request) throws -> Response {
        guard let responder = route(request) else { throw RouterError.missingRoute(for: request) }
        return try responder.respond(to: request)
    }
}

public enum RouterError: Debuggable {
    case missingRoute(for: Request)
    case unspecified(Swift.Error)
}

extension RouterError {
    public var identifier: String {
        switch self {
        case .missingRoute:
            return "missingRoute"
        case .unspecified:
            return "unspecified"
        }
    }

    public var reason: String {
        switch self {
        case .missingRoute(let request):
            return "no route found for \(request)"
        case .unspecified(let error):
            return "unspecified \(error)"
        }
    }

    public var suggestedFixes: [String] {
        switch self {
        case .missingRoute(let request):
            return [
                "ensure that a route for path '\(request.uri.path)' exists",
                "verify the host and httpmethod for the request are as expected",
                "log the routes of your router with `router.routes`"
            ]
        case .unspecified(_):
            return [
                "look into upgrading to a version that expects this error",
                "try to understand which module threw this error and where it came from"
            ]
        }
    }

    public var possibleCauses: [String] {
        return [
            "received a route that is not supported by the router"
        ]
    }
}
