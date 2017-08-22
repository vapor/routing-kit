import HTTP

/// A basic router
public final class TrieRouter: Router {
    /// The root node
    var root: Node

    public init() {
        self.root = Node(at: .constant("root"))
    }

    public func register(responder: Responder, at path: [PathComponent]) {
        var iterator = path.makeIterator()

        var current: Node = root

        while let path = iterator.next() {
            if let node = current.child(at: path) {
                current = node
            } else {
                let new = Node(at: path)
                current.children.append(new)
                current = new
            }
        }

        current.responder = responder
    }

    public func route(path: [String], parameters: inout ParameterBag) -> Responder? {
        var iterator = path.makeIterator()

        var current: Node = root

        while let path = iterator.next() {
            if let node = current.child(at: .constant(path)) {
                current = node
            } else if let (node, param) = current.childParameter() {
                let lazy = LazyParameter(type: param, value: path)
                parameters.parameters.append(lazy)
                current = node
            } else {
                return nil
            }
        }

        return current.responder
    }

}

// MARK: Node

extension TrieRouter {
    /// A node used to keep track of routes
    final class Node {
        /// All routes directly underneath this path
        var children: [Node]

        /// This nodes path componenet
        let path: PathComponent

        /// This node's resopnder
        var responder: Responder?

        /// Creates a new RouterNode
        init(at path: PathComponent) {
            self.path = path
            self.children = []
        }
    }
}

extension TrieRouter.Node {
    func child(at path: PathComponent) -> TrieRouter.Node? {
        for child in children {
            switch (child.path, path) {
            case (.constant(let a), .constant(let b)):
                if a == b {
                    return child
                }
            case (.parameter, .parameter):
                return child
            default:
                break
            }
        }
        return nil
    }


    func childParameter() -> (TrieRouter.Node, Parameter.Type)? {
        for child in children {
            switch child.path {
            case .constant:
                continue
            case .parameter(let param):
                return (child, param)
            }
        }

        return nil
    }
}
