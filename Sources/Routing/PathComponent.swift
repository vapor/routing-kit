/// Components of a router path.
public enum PathComponent {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component.
    case parameter(String)
    
    /// Any set of components
    case anything
}

extension Array where Element == PathComponent {
    var readable: String {
        return "/" + map {
            switch $0 {
            case .constant(let s): return s
            case .parameter(let p): return ":\(p)"
            case .anything: return "*"
            }
        }.joined(separator: "/")
    }
}

/// Capable of being represented by dynamic path components.
public protocol PathComponentsRepresentable {
    /// Convert to path component.
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
