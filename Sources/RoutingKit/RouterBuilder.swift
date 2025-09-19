public protocol RouterBuilder: Sendable {
    /// Type of value stored in routes.
    associatedtype Output

    /// Registers a new `Output` to the `Router` at a given path.
    ///
    /// - Parameters:
    ///   - output: Output to register.
    ///   - path: Path to register output at.
    mutating func register(_ output: Output, at path: [PathComponent])
}
