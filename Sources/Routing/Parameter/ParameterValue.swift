/// A `Paremeter`'s slug and its resolved value.
public struct ParameterValue {
    /// The `routingSlug` of a `Parameter`.
    public let slug: String

    /// Resolved parameter value from the routed path.
    public let value: String

    /// Creates a new `ParameterValue`.
    ///
    /// - parameters:
    ///     - slug: The `routingSlug` of a `Parameter`.
    ///     - value: Resolved parameter value from the routed path.
    public init(slug: String, value: String) {
        self.slug = slug
        self.value = value
    }
}
