final class TrieRouterNode<Output> {
    /// Kind of node
    var string: String

    /// All constant child nodes
    var constants: [TrieRouterNode<Output>]

    var parameter: TrieRouterNode<Output>?

    var fallback: TrieRouterNode<Output>?

    /// This node's output
    var output: Output?

    init(
        string: String,
        constants: [TrieRouterNode<Output>] = [],
        parameter: TrieRouterNode<Output>? = nil,
        fallback: TrieRouterNode<Output>? = nil,
        output: Output? = nil
    ) {
        self.string = string
        self.constants = constants
        self.parameter = parameter
        self.fallback = fallback
        self.output = output
    }

    func child(for component: PathComponent) -> TrieRouterNode<Output> {
        switch component {
        case .constant(let string):
            // search for existing constant
            for constant in constants {
                if constant.string == string {
                    return constant
                }
            }

            // none found, add a new node
            let node = TrieRouterNode<Output>(string: string)
            constants.append(node)
            return node
        case .parameter(let string):
            let node: TrieRouterNode<Output>
            if let parameter = self.parameter {
                node = parameter
            } else {
                node = TrieRouterNode<Output>(string: string)
                self.parameter = node
            }
            return node
        case .anything:

            let node: TrieRouterNode<Output>
            if let fallback = self.fallback {
                node = fallback
            } else {
                node = TrieRouterNode<Output>(string: "*")
                self.fallback = node
            }
            return node
        }
    }
}
