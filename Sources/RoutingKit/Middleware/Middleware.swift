public protocol BaseInitializable {
    init()
}

public protocol Middleware {
    associatedtype Input
    associatedtype Output: BaseInitializable
    
//    func respond<R: Responder>(to input: Input, chainingTo next: R) throws -> Output where R.Input == Input, R.Output == Output
    func handle(input: Input) -> Output
}

public protocol Responder {
    associatedtype Input
    associatedtype Output
    
    func respond(to input: Input) throws -> Output
}


internal struct MiddlewareResponder<M, R>: Responder
where R: Responder, M: Middleware, R.Input == M.Input, R.Output == M.Output {
    var middleware: [M]
    var responder: R
    
    init(middleware: [M], responder: R) {
        self.middleware = middleware
        self.responder = responder
    }
    
    func respond(to input: M.Input) -> M.Output {
        let responderOutput = self.middleware.reduce(M.Output()) { output, middleware in
            return middleware.handle(input: input)
        }
        
        return responderOutput
    }
}
