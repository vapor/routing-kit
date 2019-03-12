public protocol Middleware {
    associatedtype Input
    associatedtype Output
    
    func respond<R: Responder>(to input: Input, chainingTo next: R) throws -> Output where R.Input == Input, R.Output == Output
}

public protocol Responder {
    associatedtype Input
    associatedtype Output
    
    func respond(to input: Input) throws -> Output
}


