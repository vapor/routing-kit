extension TrieRouter {
    
    /// Creates a new `Router` that will automatically prepend the supplied path components.
    ///
    ///     let users = router.grouped([.constant("users")])
    ///     // Adding "user/auth/" route to router.
    ///     users.register(route: Route(path: [.constant("auth")], output: 1))
    ///     // adding "user/profile/" route to router
    ///     users.register(route: Route(path: [.constant("profile")], output: 2))
    ///
    /// - parameters:
    ///     - prefix: Group path components.
    /// - returns: Newly created `Router` wrapped in the path.
    public func grouped(_ prefix: [PathComponent]) -> TrieRouter<Output> {
        return TrieRouter(
            prefix: self.prefix + prefix,
            baseRouter: self.baseRouter ?? self
        )
    }
}
