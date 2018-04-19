/// Generic router built using the "trie" tree algorithm.
/// See https://en.wikipedia.org/wiki/Trie for more information.
public final class TrieRouter<Output> {
    /// All routes registered to this router
    public private(set) var routes: [Route<Output>]
    
    /// If a route cannot be found, this is the fallback output that will be used instead
    public var fallback: Output?
    
    /// If `true`, constants are compared case insensitively
    public var caseInsensitive: Bool {
        get { return compareOptions.contains(.caseInsensitive) }
        set {
            if newValue {
                compareOptions.insert(.caseInsensitive)
            } else {
                compareOptions.remove(.caseInsensitive)
            }
        }
    }

    /// The root node
    private var root: TrieRouterNode<Output>

    private var compareOptions: String.CompareOptions

    /// Create a new trie router
    public init() {
        self.root = TrieRouterNode<Output>(string: "/")
        self.routes = []
        self.compareOptions = []
    }

    /// Registers a route.
    public func register(route: Route<Output>) {
        // store the route so that we can access its metadata later if needed
        routes.append(route)

        // start at the root of the trie branch
        var current = root

        // for each dynamic path in the route get the appropriate
        // child generating a new one if necessary
        for component in route.path {
            current = current.child(for: component)
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

    /// See Router.route()
    public func route(path: [String], parameters: ParameterContainer) -> Output? {
        // always start at the root node
        var currentNode: TrieRouterNode = root

        // traverse the string path supplied
        search: for path in path {
            // check the constants first
            for constant in currentNode.constants {
                if path.compare(constant.string, options: compareOptions) == .orderedSame {
                    currentNode = constant
                    continue search
                }
            }

            // no constants matched, check for dynamic members
            if let parameter = currentNode.parameter {
                // if no constant routes were found that match the path, but
                // a dynamic parameter child was found, we can use it
                let lazy = ParameterValue(slug: parameter.string, value: path)
                parameters.parameters.append(lazy)
                currentNode = parameter
                continue search
            }

            // no constants or dynamic members, check for fallbacks
            if let fallback = currentNode.fallback {
                currentNode = fallback
                continue search
            }

            // no matches, stop searching
            return fallback
        }
        
        // return the currently resolved responder if there hasn't been an early exit.
        return currentNode.output ?? fallback
    }
}
