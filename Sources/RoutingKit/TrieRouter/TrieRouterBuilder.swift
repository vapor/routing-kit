public import Logging

// A builder for constructing ``TrieRouter`` instances using the trie data structure.
///
/// ``TrieRouterBuilder`` provides an efficient way to build routing tables by accumulating
/// route registrations and then constructing an immutable, thread-safe ``TrieRouter`` for fast lookups.
///
/// ## Configuration Options
///
/// - `.caseInsensitive`: Enables case-insensitive route matching
///
/// **Note**: Route registration is cumulative - each call to ``register(_:at:)`` adds to
///   the existing routes. Registering the same path twice will override the previous output.
///
/// **Important**: The builder uses immutable data structures internally, so route registration
///   requires `mutating` access but the final router is completely immutable.
///
/// See [Trie on Wikipedia](https://en.wikipedia.org/wiki/Trie) for more information
/// about the underlying data structure.
public struct TrieRouterBuilder<Output: Sendable>: RouterBuilder {
    typealias Node = TrieRouterNode<Output>

    /// Configured options such as case-sensitivity.
    public let config: TrieRouter<Output>.Configuration

    /// Configured logger.
    let logger: Logger

    var root: Node

    /// Create a new ``TrieRouterBuilder``.
    ///
    /// - Parameters:
    ///   - type: The output type for the router.
    ///   - options: Configured options such as case-sensitivity.
    public init(_ type: Output.Type = Output.self, config: TrieRouter<Output>.Configuration = .init()) {
        self.root = Node()
        self.config = config
        self.logger = .init(label: "codes.vapor.routingkit")
    }

    /// Create a new ``TrieRouterBuilder``.
    ///
    /// - Parameters:
    ///   - type: The output type for the router.
    ///   - options: Configured options such as case-sensitivity.
    ///   - logger: A logger for the router to use.
    public init(_ type: Output.Type = Output.self, config: TrieRouter<Output>.Configuration = .init(), logger: Logger) {
        self.root = Node()
        self.config = config
        self.logger = logger
    }

    /// Constructs a new ``TrieRouter`` based on the routes registered to this builder.
    /// - Returns: a ``TrieRouter``.
    public func build() -> TrieRouter<Output> {
        .init(builder: self)
    }

    /// Registers a new route to this router at a given path.
    ///
    ///     let route = Route(...)
    ///     let router = TrieRouter<Route>()
    ///     router.register(route, at: [.constant("users"), User.parameter])
    ///
    /// - Parameters:
    ///   - output: Output to register.
    ///   - path: Path to register output at.
    public mutating func register(_ output: Output, at path: [PathComponent]) {
        assert(!path.isEmpty, "Cannot register a route with an empty path.")
        root = insertRoute(node: root, path: path[...], output: output)
    }

    /// Recursively inserts a route into the trie, returning a new root node with the route added.
    private func insertRoute(node: Node, path: ArraySlice<PathComponent>, output: Output) -> Node {
        guard let component = path.first else {
            // At leaf: set output, preserve children
            if node.output != nil {
                self.logger.info("[Routing] Overriding duplicate route for leaf")
            }
            return node.copyWith(output: output)
        }

        let isCaseInsensitive = config.isCaseInsensitive
        switch component {
        case .constant(let string):
            let key = isCaseInsensitive ? string.lowercased() : string
            var constants = node.constants
            let child = constants[key] ?? Node()
            constants[key] = insertRoute(node: child, path: path.dropFirst(), output: output)
            return node.copyWith(constants: constants)
        case .parameter(let name):
            let wildcard = node.wildcard
            let child: Node
            if let existing = wildcard {
                if let existingName = existing.parameter {
                    precondition(
                        existingName == name,
                        "It is not possible to have two routes with the same prefix but different parameter names, even if the trailing path components differ (tried to add route with \(name) that collides with \(existingName))."
                    )
                }
                child = existing.node
            } else {
                child = Node()
            }
            let newWildcard = Node.Wildcard(
                node: insertRoute(node: child, path: path.dropFirst(), output: output), parameter: name,
                explicitlyIncludesAnything: wildcard?.explicitlyIncludesAnything ?? false
            )
            return node.copyWith(wildcard: newWildcard)
        case .catchall:
            precondition(path.count == 1, "Catchall must be the last component in a path.")
            let newCatchall = insertRoute(node: node.catchall ?? Node(), path: path.dropFirst(), output: output)
            return node.copyWith(catchall: newCatchall)
        case .anything:
            let child: Node
            if let wildcard = node.wildcard {
                child = wildcard.node
            } else {
                child = Node()
            }
            let newWildcard = Node.Wildcard(
                node: insertRoute(node: child, path: path.dropFirst(), output: output),
                parameter: node.wildcard?.parameter,
                explicitlyIncludesAnything: true
            )
            return node.copyWith(wildcard: newWildcard)
        case .partialParameter(let template, let components, let parameters):
            var partials = node.partials ?? []
            let child = partials.first(where: { $0.template == template })?.node ?? Node()
            let updatedChild = insertRoute(node: child, path: path.dropFirst(), output: output)
            partials.append(.init(template: template, components: components, parameters: parameters, node: updatedChild))
            partials.sort { $0.ambiguity < $1.ambiguity }
            return node.copyWith(partials: partials)
        }
    }
}

extension TrieRouterNode.PartialMatch {
    var ambiguity: Int {
        // A bit naïve but it works
        self.parameters.count
    }
}
