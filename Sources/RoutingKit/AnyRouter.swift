/// A router that performs type erasure by wrapping another router.
@available(*, deprecated, message: "This type is no longer useful in Swift 5.7")
public struct AnyRouter<Output>: Router {
    private let box: _AnyRouterBase<Output>
    
    public init<Router>(_ base: Router) where Router: RoutingKit.Router, Router.Output == Output {
        self.box = _AnyRouterBox(base)
    }
    
    public func register(_ output: Output, at path: [PathComponent]) {
        box.register(output, at: path)
    }
    
    public func route(path: [String], parameters: inout Parameters) -> Output? {
        box.route(path: path, parameters: &parameters)
    }
}

extension Router {
    /// Wraps this router with a type eraser.
    @available(*, deprecated, message: "This method is no longer useful in Swift 5.7")
    public func eraseToAnyRouter() -> AnyRouter<Output> {
        return AnyRouter(self)
    }
}

private class _AnyRouterBase<Output>: Router {
    init() {
        guard type(of: self) != _AnyRouterBase.self else {
            fatalError("_AnyRouterBase<Output> instances cannot be created. Subclass instead.")
        }
    }
    
    func register(_ output: Output, at path: [PathComponent]) {
        fatalError("Must be overridden")
    }
    
    func route(path: [String], parameters: inout Parameters) -> Output? {
        fatalError("Must be overridden")
    }
}

private final class _AnyRouterBox<Concrete>: _AnyRouterBase<Concrete.Output> where Concrete: Router {
    private var concrete: Concrete
    
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }
    
    override func register(_ output: Output, at path: [PathComponent]) {
        concrete.register(output, at: path)
    }
    
    override func route(path: [String], parameters: inout Parameters) -> Concrete.Output? {
        concrete.route(path: path, parameters: &parameters)
    }
}
