import HTTP

extension Router {
    public func route(request: Request) -> Responder? {
        let path = [request.method.string] + request.uri.path.split(separator: "/").map(String.init)
        return self.route(path: path, parameters: &request.parameters)
    }
}

extension Request {
    public var parameters: ParameterBag {
        // FIXME: w/ extendable
        get { return ParameterBag() }
        set { }
    }
}

