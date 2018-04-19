import Debugging

/// Errors that can be thrown while working with Routing.
public struct RoutingError: Debuggable {
    /// See `Debuggable`.
    public static let readableName = "Routing Error"

    /// See `Debuggable`.
    public var identifier: String

    /// See `Debuggable`.
    public var reason: String

    /// See `Debuggable`.
    public var sourceLocation: SourceLocation?

    /// See `Debuggable`.
    public var stackTrace: [String]

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
        self.sourceLocation = SourceLocation(file: file, function: function, line: line, column: column, range: nil)
        self.stackTrace = RoutingError.makeStackTrace()
    }
}

internal func debugOnly(_ body: () -> Void) {
    assert({ body(); return true }())
}
