import HTTP

/// Grouping implementation similar to RouteBuilder+Grouping but using MetadataRouteBuilder

extension MetadataRouteBuilder {
    /// Group all subsequent routes built with this builder
    /// under this specified host
    ///
    /// the last host in the chain will take precedence, for example:
    ///
    /// if using:
    /// grouped(host: "0.0.0.0").grouped(host: "196.08.0.1")
    ///
    /// will bind subsequent additions to '196.08.0.1'
    public func metadataGrouped(host: String) -> MetadataRouteBuilder {
        return MetadataRouteGroup(host: host, pathPrefix: [], middleware: [], parent: self)
    }
    
    /// Group all subsequent routes behind a specified path prefix
    /// use `,` separated list or `/` separated string
    /// for example, the following are all equal
    ///
    /// "a/path/to/foo"
    /// "a", "path", "to", "foo"
    /// "a/path", "to/foo"
    public func metadataGrouped(_ path: String...) -> MetadataRouteBuilder {
        return metadataGrouped(path)
    }
    
    /// - see grouped(_ path: String...)
    public func metadataGrouped(_ path: [String]) -> MetadataRouteBuilder {
        let components = path.pathComponents
        return MetadataRouteGroup(host: nil, pathPrefix: components, middleware: [], parent: self)
    }
    
    /// Group all subsequent routes to pass through specified middleware
    /// use `,` separated list for multiple middleware
    public func metadataGrouped(_ middleware: Middleware...) -> MetadataRouteBuilder {
        return metadataGrouped(middleware)
    }
    
    // FIXME: External arg necessary on middleware groups?
    
    /// - see grouped(middleware: Middleware...)
    public func metadataGrouped(_ middleware: [Middleware]) -> MetadataRouteBuilder {
        return MetadataRouteGroup(host: nil, pathPrefix: [], middleware: middleware, parent: self)
    }
}

// MARK: Closures

extension MetadataRouteBuilder {
    /// Closure based variant of grouped(host: String)
    public func metadataGroup(host: String, handler: (MetadataRouteBuilder) -> ()) {
        let builder = metadataGrouped(host: host)
        handler(builder)
    }
    
    /// Closure based variant of grouped(_ path: String...)
    public func metadataGroup(_ path: String ..., handler: (MetadataRouteBuilder) -> ()) {
        metadataGroup(path: path, handler: handler)
    }
    
    /// Closure based variant of grouped(_ path: [String])
    public func metadataGroup(path: [String], handler: (MetadataRouteBuilder) -> ()) {
        let path = path.pathComponents
        let builder = metadataGrouped(path)
        handler(builder)
    }
    
    // FIXME: Need external parameter cohesiveness
    /// Closure based variant of grouped(middleware: Middleware...)
    public func metadataGroup(_ middleware: Middleware..., handler: (MetadataRouteBuilder) -> ()) {
        metadataGroup(middleware: middleware, handler: handler)
    }
    
    /// Closure based variant of grouped(middleware: [Middleware])
    public func metadataGroup(middleware: [Middleware], handler: (MetadataRouteBuilder) -> ()) {
        let builder = metadataGrouped(middleware)
        handler(builder)
    }
}

