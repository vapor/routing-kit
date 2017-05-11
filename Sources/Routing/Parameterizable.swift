public protocol Parameterizable {
    /// the unique key to use as a slug in route building
    static var uniqueSlug: String { get }
    
    // returns the found model for the resolved url parameter
    static func make(for parameter: String) throws -> Self
}

extension Parameterizable {
    /// The key to be used when a result of this type is extracted from a route.
    ///
    /// Given the following example:
    ///
    /// ```
    /// drop.get("users", User.parameter) { req in
    ///     let user = try req.parameters.get(User.self)
    /// }
    ///
    /// ```
    ///
    /// the generated route will be /users/**:user**
    public static var parameter: String {
        return ":" + uniqueSlug
    }
}

extension String: Parameterizable {
    public static var uniqueSlug: String {
        return "string"
    }
    
    public static func make(for parameter: String) throws -> String {
        return parameter
    }
}
extension Int: Parameterizable {
    public static var uniqueSlug: String {
        return "int"
    }
    
    public static func make(for parameter: String) throws -> Int {
        guard let int = Int(parameter) else {
            throw RouterError.invalidParameter
        }
        
        return int
    }
}
