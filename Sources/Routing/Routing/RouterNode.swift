/// A single node of the `Router`s trie tree of routes.
final class RouterNode<Output> {
    /// Kind of node
    var value: Data

    /// All constant child nodes.
    var constants: [RouterNode<Output>]

    /// Parameter child node, if one exists.
    var parameter: RouterNode<Output>?

    /// Catchall node, if one exists.
    /// This node should not have any child nodes.
    var catchall: RouterNode<Output>?

    /// Anything child node, if one exists.
    var anything: RouterNode<Output>?

    /// This node's output
    var output: Output?

    /// Creates a new `RouterNode`.
    init(value: Data, output: Output? = nil) {
        self.value = value
        self.output = output
        self.constants = []
    }

    /// Fetches the child `RouterNode` for the supplied path component, or builds
    /// a new segment onto the tree if necessary.
    func buildOrFetchChild(for component: PathComponent) -> RouterNode<Output> {
        switch component {
        case .constant(let string):
            // Do string <-> data conversion here
            //
            // Performance doesn't really matter since this code should only
            // be called during registration phase.
            let value = Data(string.utf8)

            // search for existing constant
            for constant in constants {
                if constant.value == value {
                    return constant
                }
            }

            // none found, add a new node
            let node = RouterNode<Output>(value: value)
            constants.append(node)
            return node
        case .parameter(let string):
            // Do string <-> data conversion here
            //
            // Performance doesn't really matter since this code should only
            // be called during registration phase.
            let value = Data(string.utf8)

            let node: RouterNode<Output>
            if let parameter = self.parameter {
                node = parameter
            } else {
                node = RouterNode<Output>(value: value)
                self.parameter = node
            }
            return node
        case .catchall:
            let node: RouterNode<Output>
            if let fallback = self.catchall {
                node = fallback
            } else {
                node = RouterNode<Output>(value: Data([.asterisk]))
                self.catchall = node
            }
            return node
        case .anything:
            let node: RouterNode<Output>
            if (self.anything == nil) {
                node = RouterNode<Output>(value: Data([.colon]))
                self.anything = node
            } else {
                node = self.anything!
            }
            return node
        }
    }
}
