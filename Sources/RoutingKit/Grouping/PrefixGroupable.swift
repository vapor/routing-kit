public class PrefixGroupedRouter<RouterType: Router> {
    public let prefix: [PathComponent]
    public var baseRouter: RouterType
    
    public init(
        prefix: [PathComponent],
        baseRouter: RouterType
    ) {
        self.prefix = prefix
        self.baseRouter = baseRouter
    }
}

extension PrefixGroupedRouter: Router {
    public func register(route: Route<RouterType.Output>) {
        let route = Route(path: self.prefix + route.path, output: route.output)
        self.baseRouter.register(route: route)
    }
    
    public func route(path: [String], parameters: inout Parameters) -> RouterType.Output? {
        return self.baseRouter.route(path: path, parameters: &parameters)
    }
}

extension Router {
    public func grouped(_ prefix: [PathComponent]) -> PrefixGroupedRouter<BaseRouterType> {
        return PrefixGroupedRouter(
            prefix: self.prefix + prefix,
            baseRouter: self.baseRouter
        )
    }
}
