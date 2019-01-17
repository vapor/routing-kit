/// A single path component of a `Route`. An array of these components describes
/// a route's path, including which parts are constant and which parts are dynamic (parameters).
public enum PathComponent: ExpressibleByStringLiteral {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component. 
    case parameter(String)
    
    /// This route will match everything that is not in other routes
    case anything
    
    /// This route will match and discard any number of constant components after
    /// this anything component.
    case catchall

    /// See `ExpressibleByStringLiteral`.
    public init(stringLiteral value: String) {
        self = .constant(value)
    }
}

/// Shortcut for accessing `PathComponent.anything`.
public let any: PathComponent = .anything
/// Shortcut for accessing `PathComponent.catchall`.
public let all: PathComponent = .catchall

extension Array where Element == PathComponent {
    /// Creates a readable representation of this array of `PathComponent`.
    public var readable: String {
        return "/" + map {
            switch $0 {
            case .constant(let s): return s
            case .parameter(let p): return ":\(p)"
            case .anything: return ":"
            case .catchall: return "*"
            }
        }.joined(separator: "/")
    }
}
