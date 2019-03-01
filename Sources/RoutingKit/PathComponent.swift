/// A single path component of a `Route`. An array of these components describes
/// a route's path, including which parts are constant and which parts are dynamic (parameters).
public enum PathComponent: ExpressibleByStringLiteral, CustomStringConvertible {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component. 
    case parameter(String)
    
    /// This route will match everything that is not in other routes
    case anything
    
    /// This route will match and discard any number of constant components after
    /// this anything component.
    case catchall

    /// `ExpressibleByStringLiteral` conformance.
    public init(stringLiteral value: String) {
        if value.hasPrefix(":") {
            self = .parameter(.init(value.dropFirst()))
        } else if value == ":" {
            self = .anything
        } else if value == "*" {
            self = .catchall
        } else {
            self = .constant(value)
        }
    }
    
    /// `CustomStringConvertible` conformance.
    public var description: String {
        switch self {
        case .anything: return ":"
        case .catchall: return "*"
        case .parameter(let name): return ":" + name
        case .constant(let constant): return constant
        }
    }
}

extension Array where Element == PathComponent {
    /// Converts an array of `PathComponent` into a readable path string.
    ///
    ///     /galaxies/:galaxyID/planets
    ///
    public var string: String {
        return self.map { $0.description }.joined(separator: "/")
    }
}
