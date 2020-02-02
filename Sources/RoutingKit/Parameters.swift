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

    /// Grabs the parameter, supplied as a `PathComponent.parameter`, from the parameter bag.
    ///
    /// For example GET /posts/:post_id/comments/:comment_id
    /// would be fetched using:
    ///
    ///     let postID = parameters.get(.postId)
    ///     let commentID = parameters.get(.commentId)
    ///
    public func get(_ parameter: PathComponent) -> String? {
        if case .parameter(let name) = parameter { return nil }
        return get(name)
    }

    /// Grabs the parameter, supplied as a `PathComponent.parameter`, from the parameter bag,
    /// casting it to a `LosslessStringConvertible` type.
    ///
    /// For example GET /posts/:post_id/comments/:comment_id
    /// would be fetched using:
    ///
    ///     let postID = parameters.get(.postId, as: Int.self)
    ///     let commentID = parameters.get(.commentId, as: Int.self)
    ///
    public func get<T>(_ parameter: PathComponent, as type: T.Type = T.self) -> T?
        where T: LosslessStringConvertible
    {
        get(parameter).flatMap(T.init)
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
        values[name]
    }

    /// Adds a new parameter value to the bag.
    ///
    /// - note: The value will be percent-decoded.
    ///
    /// - parameters:
    ///     - name: Unique parameter name
    ///     - value: Value (percent-encoded if necessary)
    public mutating func set(_ name: String, to value: String?) {
        values[name] = value?.removingPercentEncoding
    }
}
