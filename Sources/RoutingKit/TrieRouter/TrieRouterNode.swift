/// A single node of the ``TrieRouter``s trie tree of routes.
final class TrieRouterNode<Output: Sendable>: Sendable, CustomStringConvertible {
    /// Describes a node that has matched a parameter or anything
    struct Wildcard: Sendable {
        let parameter: String?
        let explicitlyIncludesAnything: Bool

        let node: TrieRouterNode

        init(node: TrieRouterNode, parameter: String? = nil, explicitlyIncludesAnything: Bool = false) {
            self.node = node
            self.parameter = parameter
            self.explicitlyIncludesAnything = explicitlyIncludesAnything
        }

        static func anything(_ node: TrieRouterNode) -> Wildcard {
            Wildcard(node: node, explicitlyIncludesAnything: true)
        }

        static func parameter(_ node: TrieRouterNode, named name: String) -> Wildcard {
            Wildcard(node: node, parameter: name)
        }

        func copyWith(
            node: TrieRouterNode? = nil,
            parameter: String? = nil,
            explicitlyIncludesAnything: Bool? = nil
        ) -> Wildcard {
            Wildcard(
                node: node ?? self.node,
                parameter: parameter ?? self.parameter,
                explicitlyIncludesAnything: explicitlyIncludesAnything ?? self.explicitlyIncludesAnything
            )
        }
    }

    /// All constant child nodes.
    let constants: [String: TrieRouterNode]

    /// Wildcard child node that may be a named parameter or an anything
    let wildcard: Wildcard?

    /// Catchall node, if one exists.
    /// This node should not have any child nodes.
    let catchall: TrieRouterNode?

    /// This node's output
    let output: Output?

    /// Creates a new `RouterNode`.
    init(output: Output? = nil, constants: [String: TrieRouterNode] = [:], wildcard: Wildcard? = nil, catchall: TrieRouterNode? = nil) {
        self.output = output
        self.constants = constants
        self.wildcard = wildcard
        self.catchall = catchall
    }

    var description: String {
        self.subpathDescriptions.joined(separator: "\n")
    }

    var subpathDescriptions: [String] {
        var desc: [String] = []
        for (name, constant) in self.constants {
            desc.append("→ \(name)")
            desc += constant.subpathDescriptions.indented()
        }

        if let wildcard = self.wildcard {
            if let name = wildcard.parameter {
                desc.append("→ :\(name)")
                desc += wildcard.node.subpathDescriptions.indented()
            }

            if wildcard.explicitlyIncludesAnything {
                desc.append("→ *")
                desc += wildcard.node.subpathDescriptions.indented()
            }
        }

        if self.catchall != nil {
            desc.append("→ **")
        }
        return desc
    }

    func copyWith(
        output: Output? = nil,
        constants: [String: TrieRouterNode]? = nil,
        wildcard: Wildcard? = nil,
        catchall: TrieRouterNode? = nil
    ) -> TrieRouterNode {
        TrieRouterNode(
            output: output ?? self.output,
            constants: constants ?? self.constants,
            wildcard: wildcard ?? self.wildcard,
            catchall: catchall ?? self.catchall
        )
    }
}

extension Array where Element == String {
    fileprivate func indented() -> [String] {
        self.map { "  " + $0 }
    }
}
