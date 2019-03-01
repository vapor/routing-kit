import Foundation

/// Holds dynamic path components that were discovered while routing.
///
/// After this struct has been filled with parameter values, you can fetch
/// them out by name using `get(_:)`.
///
///     let postID = parameters.get("post_id")
///
public struct Parameters {
    /// Internal storage.
    private var values: [String: String]

    /// Creates a new `Parameters`.
    ///
    /// Pass this into the `Router.route(path:parameters:)` method to fill with values.
    public init() {
        values = [:]
    }

    /// Grabs the named parameter from the parameter bag.
    ///
    /// For example GET /posts/:post_id/comments/:comment_id
    /// would be fetched using:
    ///
    ///     let postID = parameters.get("post_id")
    ///     let commentID = parameters.get("comment_id")
    ///
    public func get(_ name: String) -> String? {
        return self.values[name]
    }
    
    /// Grabs the named parameter from the parameter bag, casting it to
    /// a `LosslessStringConvertible` type.
    ///
    /// For example GET /posts/:post_id/comments/:comment_id
    /// would be fetched using:
    ///
    ///     let postID = parameters.get("post_id", as: Int.self)
    ///     let commentID = parameters.get("comment_id", as: Int.self)
    ///
    public func get<T>(_ name: String, as type: T.Type) -> T?
        where T: LosslessStringConvertible
    {
        return self.get(name).flatMap(T.init)
    }
    
    /// Adds a new parameter value to the bag.
    ///
    /// - note: The value will be percent-decoded.
    ///
    /// - parameters:
    ///     - name: Unique parameter name
    ///     - value: Value (percent-encoded if necessary)
    public mutating func set(_ name: String, to value: String?) {
        self.values[name] = value?.removingPercentEncoding
    }
}
