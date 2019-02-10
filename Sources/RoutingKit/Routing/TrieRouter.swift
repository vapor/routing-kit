import Foundation

/// Generic `TrieRouter` built using the "trie" tree algorithm.
///
/// Use `register(...)` to register routes into the router. Use `route(...)` to then fetch a matching
/// route's output.
///
/// See https://en.wikipedia.org/wiki/Trie for more information.
public final class TrieRouter<Output>: CustomStringConvertible {
    /// Configured options such as case-sensitivity.
    public var options: Set<RouterOption>

    /// The root node.
    private var root: Node

    /// Create a new `TrieRouter`.
    ///
    /// - parameters:
    ///     - options: Configured options such as case-sensitivity.
    public init(_ type: Output.Type = Output.self, options: Set<RouterOption> = []) {
        self.root = Node(value: "/")
        self.options = options
    }

    /// Registers a new `Route` to this router.
    ///
    ///     let route = Route<Int>(path: [.constant("users"), User.parameter], output: ...)
    ///     let router = TrieRouter<Int>()
    ///     router.register(route: route)
    ///
    /// - parameters:
    ///     - route: `Route` to register to this router.
    public func register(route: Route<Output>) {
        // start at the root of the trie branch
        var current = self.root

        // for each dynamic path in the route get the appropriate
        // child generating a new one if necessary
        for component in route.path {
            current = current.buildOrFetchChild(for: component, options: self.options)
        }

        // after iterating over all path components, we can set the output
        // on the current node
        debugOnly {
            if current.output != nil {
                print("[Routing] Warning: Overriding route output at: \(route.path.readable)")
            }
        }
        current.output = route.output
    }

    /// Routes a `path`, returning the best-matching output and collecting any dynamic parameters.
    ///
    ///     var params = Parameters()
    ///     router.route(path: ["users", "Vapor"], parameters: &params)
    ///
    /// - parameters:
    ///     - path: Array of `RoutableComponent` to route against.
    ///     - params: A mutable `Parameters` to collect dynamic parameters.
    /// - returns: Best-matching output for the supplied path.
    public func route(path: [String], parameters: inout Parameters) -> Output? {
        // always start at the root node
        var currentNode: Node = self.root
        
        let ci = self.options.contains(.caseInsensitive)

        // traverse the string path supplied
        search: for path in path {
            // check the constants first
            for constant in currentNode.constants {
                let match: Bool
                
                // Short circuit early if items are different lengths
                if constant.value.count != path.count {
                    match = false
                } else if ci {
                    // constant.value will already be lowercased
                    match = constant.value == path.lowercased()
                } else {
                    match = constant.value == path
                }
               
                if match {
                    currentNode = constant
                    continue search
                }
            }

            // no constants matched, check for dynamic members
            if let parameter = currentNode.parameter {
                // if no constant routes were found that match the path, but
                // a dynamic parameter child was found, we can use it
                let value = ParameterValue(
                    slug: parameter.value,
                    value: path
                )
                parameters.values.append(value)
                currentNode = parameter
                continue search
            }

            // check for anythings
            if let anything = currentNode.anything {
                currentNode = anything
                continue search
            }

            // no constants or dynamic members, check for catchall
            if let catchall = currentNode.catchall {
                // there is a catchall and it is final, short-circuit to its output
                return catchall.output
            }

            // no matches, stop searching
            return nil
        }

        // return the currently resolved responder if there hasn't been an early exit.
        return currentNode.output
    }
    
    public var description: String {
        return self.root.description
    }
}
