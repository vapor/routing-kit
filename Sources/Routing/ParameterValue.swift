/// A parameter and its resolved value.
public struct ParameterValue {
    /// The parameter type.
    public let slug: String

    /// The resolved value.
    public let value: String

    /// Create a new lazy parameter.
    public init(slug: String, value: String) {
        self.slug = slug
        self.value = value
    }
}
