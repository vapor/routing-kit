/// A single path component of a `Route`. An array of these components describes
/// a route's path, including which parts are constant and which parts are dynamic.
public enum PathComponent: ExpressibleByStringInterpolation, CustomStringConvertible, Sendable {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component.
    ///
    /// The supplied identifier will be used to fetch the associated
    /// value from `Parameters`.
    ///
    /// Represented as `:` followed by the identifier.
    case parameter(String)

    // case partialParameter(String, regex: any (RegexComponent & Sendable))
    case partialParameter(String, regex: String)

    /// A dynamic parameter component with discarded value.
    ///
    /// Represented as `*`
    case anything

    /// A fallback component that will match one *or more* dynamic
    /// parameter components with discarded values.
    ///
    /// Catch alls have the lowest precedence, and will only be matched
    /// if no more specific path components are found.
    ///
    /// The matched subpath will be stored into `Parameters.catchall`.
    ///
    /// Represented as `**`
    case catchall

    // See `ExpressibleByStringLiteral.init(stringLiteral:)`.
    public init(stringLiteral value: String) {
        // We create a regex out of the string that we can then compare to the route and
        // fetch the named parameters from
        if value.contains("{") {
            precondition(value.contains("}"), "Malformed path component")
            var regex = ""
            var name = ""
            var inBraces = false

            for char in value.dropFirst() {
                switch char {
                case "{":
                    inBraces = true
                    name = ""
                case "}":
                    inBraces = false
                    regex += "(?<\(name)>[^/]+)"
                default:
                    if inBraces {
                        name.append(char)
                    } else {
                        if ".+*?^$()[]{}|\\".contains(char) {
                            regex.append("\\\(char)")
                        } else {
                            regex.append(char)
                        }
                    }
                }
            }
            self = .partialParameter(String(value.dropFirst()), regex: regex)
        } else if value.hasPrefix(":") {
            self = .parameter(.init(value.dropFirst()))
        } else if value == "*" {
            self = .anything
        } else if value == "**" {
            self = .catchall
        } else {
            self = .constant(value)
        }
    }

    // See `CustomStringConvertible.description`.
    public var description: String {
        switch self {
        case .anything: "*"
        case .catchall: "**"
        case .parameter(let name): ":" + name
        case .constant(let constant): constant
        case .partialParameter(let value, _): value
        }
    }
}

extension String {
    /// Converts a string into an array of ``PathComponent``.
    public var pathComponents: [PathComponent] {
        self.split(separator: "/").map { .init(stringLiteral: .init($0)) }
    }
}

extension Sequence where Element == PathComponent {
    /// Converts an array of ``PathComponent`` into a readable path string.
    ///
    ///     galaxies/:galaxyID/planets
    ///
    public var string: String {
        self.map(\.description).joined(separator: "/")
    }
}
