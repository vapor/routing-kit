public protocol Parameterizable {
    /// the unique key to use as a slug in route building
    static var uniqueSlug: String { get }
    
    // returns the found model for the resolved url parameter
    static func make(for parameter: String) throws -> Self
}

extension Parameterizable {
    public static var parameter: String {
        return ":" + uniqueSlug
    }
}
