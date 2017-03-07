extension String {
    /// Separates a URI path into
    /// an array by splitting on `/`
    internal var pathComponents: [String] {
        return characters
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0) }
    }
}

extension Sequence where Iterator.Element == String {
    /// Ensures that `/` are interpreted properly on arrays
    /// of path components, so `["foo", "bar/dar"]`
    /// will expand to `["foo", "bar", "dar"]`
    internal var pathComponents: [String] {
        return flatMap { $0.pathComponents } .filter { !$0.isEmpty }
    }
}
