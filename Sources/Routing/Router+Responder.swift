import HTTP
import Branches
import Debugging

public var supportOptionsRequests = true

extension Router: Responder {
    public func respond(to request: Request) throws -> Response {
        guard let responder = route(request) else { return try fallbackResponse(for: request) }
        return try responder.respond(to: request)
    }

    private func fallbackResponse(for request: Request) throws -> Response {
        guard supportOptionsRequests, request.method == .options else { throw RouterError.missingRoute(for: request) }
        return options(for: request)
    }

    private func options(for request: Request) -> Response {
        let opts = supportedMethods(for: request)
            .map { $0.description }
            .joined(separator: ", ")
        return Response(status: .ok, headers: ["Allow": opts])
    }

    private func supportedMethods(for request: Request) -> [Method] {
        let request = request.copy()
        guard let host = self.host(for: request.uri.hostname) else { return [] }
        let allOptions = host.allSubBranches
        let allPossibleMethods = allOptions.map { Method($0.name) }
        return allPossibleMethods.filter { method in
            request.method = method
            return route(request) != nil
        }
    }

    private func host(for host: String) -> Branch<Responder>? {
        return base.fetch([host])
    }
}

extension Request {
    public func copy() -> Request {
        return Request(
            method: method,
            uri: uri,
            version: version,
            headers: headers,
            body: body,
            peerAddress: peerAddress
        )
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
