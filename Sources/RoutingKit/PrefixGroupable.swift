public protocol PrefixGroupable: Router {
    associatedtype RouterType: PrefixGroupable
    func grouped(_ prefix: [PathComponent]) -> RouterType
}


public class PrefixGroupedRouter<Output, RouterType: Router> where Output == RouterType.Output {
    let prefix: [PathComponent]
    var baseRouter: RouterType
    
    public init(
        _ outputType: Output.Type = Output.self,
        prefix: [PathComponent],
        baseRouter: RouterType
    ) {
        self.prefix = prefix
        self.baseRouter = baseRouter
    }
}

extension PrefixGroupedRouter: Router {
    public func register(route: Route<Output>) {
        let route = Route(path: self.prefix + route.path, output: route.output)
        self.baseRouter.register(route: route)
    }
    
    public func route(path: [String], parameters: inout Parameters) -> Output? {
        return self.baseRouter.route(path: path, parameters: &parameters)
    }
}

extension PrefixGroupedRouter: PrefixGroupable {
    public func grouped(_ prefix: [PathComponent]) -> PrefixGroupedRouter {
        return PrefixGroupedRouter(Output.self, prefix: self.prefix + prefix, baseRouter: self.baseRouter)
    }
}
