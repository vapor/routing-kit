/// An object that can quickly look up previously registered routes.
///
/// See ``TrieRouter`` for concrete implementation.
public protocol Router {
    /// Type of value stored in routes. This will be returned by the router.
    associatedtype Output

    /// Registers a new `Output` to the `Router` at a given path.
    ///
    /// - Parameters:
    ///   - output: Output to register.
    ///   - path: Path to register output at.
    mutating func register(_ output: Output, at path: [PathComponent])

    /// Fetches output for a specific route.
    ///
    /// ``PathComponent/parameter(_:)`` values will be stored in the supplied ``Parameters``
    /// container during routing.
    ///
    /// If no matching route is found, `nil` is returned.
    ///
    /// - Parameters:
    ///   - path: Raw path segments.
    ///   - parameters: Will collect dynamic parameter values.
    /// - Returns: Output of matching route, if found.
    func route(path: [String], parameters: inout Parameters) -> Output?
}
