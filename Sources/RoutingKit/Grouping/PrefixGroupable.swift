extension TrieRouter {
    public func grouped(_ prefix: [PathComponent]) -> TrieRouter<Output> {
        return TrieRouter(
            prefix: self.prefix + prefix,
            baseRouter: self.baseRouter ?? self
        )
    }
}
