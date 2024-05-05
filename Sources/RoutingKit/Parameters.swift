import Foundation
import Logging

/// Holds dynamic path components that were discovered while routing.
///
/// After this struct has been filled with parameter values, you can fetch
/// them out by name using ``get(_:)`` or ``get(_:as:)``.
///
///     let postID = parameters.get("post_id")
///
public struct Parameters: Sendable {
    /// Internal storage.
    private var values: [String: String]
    private var catchall: Catchall
    
    /// The configured logger.
    public let logger: Logger

    /// Return a list of all parameter names which were captured. Does not include values listed in the catchall.
    public var allNames: Set<String> { .init(self.values.keys) }

    /// Create a new `Parameters`.
    ///
    /// Pass this to ``Router/route(path:parameters:)`` to fill with values.
    public init() {
        self.values = [:]
        self.catchall = Catchall()
        self.logger = Logger(label: "codes.vapor.routingkit")
    }
    
    /// Create a new `Parameters`.
    ///
    /// Pass this to ``Router/route(path:parameters:)`` to fill with values.
    ///
    /// - Parameter logger: The logger to be used. If none is provided, a default one will be created.
    public init(_ logger: Logger?) {
        self.values = [:]
        self.catchall = Catchall()
        self.logger = logger ?? Logger(label: "codes.vapor.routingkit")
    }

    /// Grabs the named parameter from the parameter bag.
    ///
    /// For example `GET /posts/:post_id/comments/:comment_id`
    /// would be fetched using:
    ///
    ///     let postID = parameters.get("post_id")
    ///     let commentID = parameters.get("comment_id")
    ///
    public func get(_ name: String) -> String? {
        self.values[name]
    }
    
    /// Grabs the named parameter from the parameter bag, casting it to
    /// a `LosslessStringConvertible` type.
    ///
    /// For example `GET /posts/:post_id/comments/:comment_id`
    /// would be fetched using:
    ///
    ///     let postID = parameters.get("post_id", as: Int.self)
    ///     let commentID = parameters.get("comment_id", as: Int.self)
    ///
    public func get<T>(_ name: String, as type: T.Type = T.self) -> T?
        where T: LosslessStringConvertible
    {
        self.get(name).flatMap(T.init)
    }
    
    /// Adds a new parameter value to the bag.
    ///
    /// > Note: The value will be percent-decoded.
    ///
    /// - Parameters:
    ///     - name: Unique parameter name
    ///     - value: Value (percent-encoded if necessary)
    public mutating func set(_ name: String, to value: String?) {
        self.values[name] = value?.removingPercentEncoding
    }
    
    /// Fetches the components matched by `catchall` (`**`).
    ///
    /// If the route doen't hit `catchall`, it'll return `[]`.
    ///
    /// You can judge whether `catchall` is hit using:
    ///
    ///     let matched = parameters.getCatchall()
    ///     guard matched.count != 0 else {
    ///         // not hit
    ///     }
    ///
    /// > Note: The value will be percent-decoded.
    ///
    /// - returns: The path components matched
    public mutating func getCatchall() -> [String] {
        if self.catchall.isPercentEncoded {
            self.catchall.values = self.catchall.values.map { $0.removingPercentEncoding ?? $0 }
            self.catchall.isPercentEncoded = false
        }
        return self.catchall.values
    }
    
    /// Stores the components matched by `catchall` (`**`).
    ///
    /// - Parameter matched: The subpaths matched (percent-encoded if necessary)
    public mutating func setCatchall(matched: [String]) {
        self.catchall = Catchall(values: matched)
    }
    
    /// Holds path components that were matched by `catchall` (`**`).
    ///
    /// Used internally.
    private struct Catchall {
        var values: [String] = []
        var isPercentEncoded: Bool = true
    }
}
