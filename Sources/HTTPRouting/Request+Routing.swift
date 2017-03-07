import Routing
import HTTP
import Node

private let parametersKey = "parameters"

extension HTTP.Request {
    /// when routing a url with slug parameters, ie:
    /// foo/:id
    /// the request will populate these values before passing to handeler
    /// for example:
    /// given route: /foo/:id
    /// and request with path `/foo/123`
    /// parameters will be `["id": 123]`
    public var parameters: Node {
        get {
            if let existing = storage[parametersKey] as? Node {
                return existing
            }

            let node = Node([:])
            storage[parametersKey] = node
            return node
        }
        set {
            storage[parametersKey] = newValue
        }
    }
}
