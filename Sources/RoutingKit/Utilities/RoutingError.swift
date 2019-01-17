#warning("TODO: consider moving to enum")
/// Errors that can be thrown while working with Routing.
public struct RoutingError: Error {
    /// See `Debuggable`.
    public var identifier: String

    /// See `Debuggable`.
    public var reason: String

    /// Creates a new `RoutingError`.
    public init(
        identifier: String,
        reason: String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.identifier = identifier
        self.reason = reason
    }
}

internal func debugOnly(_ body: () -> Void) {
    assert({ body(); return true }())
}
