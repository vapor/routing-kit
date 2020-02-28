import Foundation

/// Holds dynamic path components that were discovered while routing.
///
/// After this struct has been filled with parameter values, you can fetch
/// them out by name using `get(_:)`.
///
///     let postID = parameters.get("post_id")
///
@dynamicMemberLookup
public struct Parameters {
    /// Internal storage.
    private var values: [String: String]

    /// Creates a new `Parameters`.
    ///
    /// Pass this into the `Router.route(path:parameters:)` method to fill with values.
    public init() {
        values = [:]
    }

    public subscript<Value>(dynamicMember paramater: KeyPath<PathComponent.Type, Parameter<Value>>) -> Value? {
        guard let raw = self.values[PathComponent.self[keyPath: paramater].name] else { return nil }
        guard let value = Value(raw) else { return nil }
        return value
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
    public func get<T>(_ name: String, as type: T.Type = T.self) -> T?
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

@propertyWrapper public struct Parameter<Value> where Value: LosslessStringConvertible {
    public let name: String

    @available(*, unavailable, message: "This property never contains a value and will always crash if you try to access it.")
    public var wrappedValue: Value { fatalError("You shouldn't ever call this ") }

    public init(name: String) {
        self.name = name
    }
}
