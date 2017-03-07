import HTTP

extension RouteBuilder {
    /// Group all subsequent routes built with this builder
    /// under this specified host
    /// 
    /// the last host in the chain will take precedence, for example:
    ///
    /// if using:
    /// grouped(host: "0.0.0.0").grouped(host: "196.08.0.1")
    ///
    /// will bind subsequent additions to '196.08.0.1'
    public func grouped(host: String) -> RouteBuilder {
        return RouteGroup(host: host, pathPrefix: [], middleware: [], parent: self)
    }

    /// Group all subsequent routes behind a specified path prefix
    /// use `,` separated list or `/` separated string
    /// for example, the following are all equal
    ///
    /// "a/path/to/foo"
    /// "a", "path", "to", "foo"
    /// "a/path", "to/foo"
    public func grouped(_ path: String...) -> RouteBuilder {
        return grouped(path)
    }

    /// - see grouped(_ path: String...)
    public func grouped(_ path: [String]) -> RouteBuilder {
        let components = path.pathComponents
        return RouteGroup(host: nil, pathPrefix: components, middleware: [], parent: self)
    }

    /// Group all subsequent routes to pass through specified middleware
    /// use `,` separated list for multiple middleware
    public func grouped(_ middleware: Middleware...) -> RouteBuilder {
        return grouped(middleware)
    }

    // FIXME: External arg necessary on middleware groups?

    /// - see grouped(middleware: Middleware...)
    public func grouped(_ middleware: [Middleware]) -> RouteBuilder {
        return RouteGroup(host: nil, pathPrefix: [], middleware: middleware, parent: self)
    }
}

// MARK: Closures

extension RouteBuilder {
    /// Closure based variant of grouped(host: String)
    public func group(host: String, handler: (RouteBuilder) -> ()) {
        let builder = grouped(host: host)
        handler(builder)
    }

    /// Closure based variant of grouped(_ path: String...)
    public func group(_ path: String ..., handler: (RouteBuilder) -> ()) {
        group(path: path, handler: handler)
    }

    /// Closure based variant of grouped(_ path: [String])
    public func group(path: [String], handler: (RouteBuilder) -> ()) {
        let path = path.pathComponents
        let builder = grouped(path)
        handler(builder)
    }

    // FIXME: Need external parameter cohesiveness
    /// Closure based variant of grouped(middleware: Middleware...)
    public func group(_ middleware: Middleware..., handler: (RouteBuilder) -> ()) {
        group(middleware: middleware, handler: handler)
    }

    /// Closure based variant of grouped(middleware: [Middleware])
    public func group(middleware: [Middleware], handler: (RouteBuilder) -> ()) {
        let builder = grouped(middleware)
        handler(builder)
    }
}
