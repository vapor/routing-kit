/// A single path component of a `Route`. An array of these components describes
/// a route's path, including which parts are constant and which parts are dynamic (parameters).
public enum PathComponent: ExpressibleByStringLiteral {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component.
    case parameter(String)
    
    /// This route will match and discard any number of constant components after
    /// this anything component.
    case anything

    /// See `ExpressibleByStringLiteral`.
    public init(stringLiteral value: String) {
        self = .constant(value)
    }
}

/// Shortcut for accessing `PathComponent.anything`.
public let any: PathComponent = .anything

extension Array where Element == PathComponent {
    /// Creates a readable representation of this array of `PathComponent`.
    public var readable: String {
        return "/" + map {
            switch $0 {
            case .constant(let s): return s
            case .parameter(let p): return ":\(p)"
            case .anything: return "*"
            }
        }.joined(separator: "/")
    }
}

/// Capable of being represented by an array of `PathComponent`.
public protocol PathComponentsRepresentable {
    /// Converts self to an array of `PathComponent`.
    func convertToPathComponents() -> [PathComponent]
}

extension PathComponent: PathComponentsRepresentable {
    /// See `PathComponentsRepresentable`.
    public func convertToPathComponents() -> [PathComponent] {
        return [self]
    }
}

extension String: PathComponentsRepresentable {
    /// See `PathComponentsRepresentable`.
    public func convertToPathComponents() -> [PathComponent] {
        return split(separator: "/").map { .constant(.init($0)) }
    }
}

extension Array: PathComponentsRepresentable where Element == PathComponentsRepresentable {
    /// Converts self to an array of `PathComponent`.
    public func convertToPathComponents() -> [PathComponent] {
        return flatMap { $0.convertToPathComponents() }
    }
}
