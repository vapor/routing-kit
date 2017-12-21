extension String {
    /// Separates a URI path into
    /// an array by splitting on `/`
    internal var pathComponents: [String] {
        return toCharacterSequence()
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

extension String {
    #if swift(>=4.0)
    internal func toCharacterSequence() -> String {
        return self
    }
    #else
    internal func toCharacterSequence() -> CharacterView {
    return self.characters
    }
    #endif
}
