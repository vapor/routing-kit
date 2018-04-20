extension TrieRouter {
    /// If `true`, constants are compared case insensitively.
    @available(*, deprecated, renamed: "options")
    public var caseInsensitive: Bool {
        get { return options.contains(.caseInsensitive) }
        set {
            if newValue {
                options.insert(.caseInsensitive)
            } else {
                options.remove(.caseInsensitive)
            }
        }
    }
}
