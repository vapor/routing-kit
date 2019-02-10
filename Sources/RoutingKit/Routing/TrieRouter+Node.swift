import Foundation

extension TrieRouter {
    /// A single node of the `Router`s trie tree of routes.
    final class Node: CustomStringConvertible {
        /// Kind of node
        var value: String
        
        /// All constant child nodes.
        var constants: [Node]
        
        /// Parameter child node, if one exists.
        var parameter: Node?
        
        /// Catchall node, if one exists.
        /// This node should not have any child nodes.
        var catchall: Node?
        
        /// Anything child node, if one exists.
        var anything: Node?
        
        /// This node's output
        var output: Output?
        
        /// Creates a new `RouterNode`.
        init(value: String, output: Output? = nil) {
            self.value = value
            self.output = output
            self.constants = []
        }
        
        /// Fetches the child `RouterNode` for the supplied path component, or builds
        /// a new segment onto the tree if necessary.
        func buildOrFetchChild(for component: PathComponent, options: Set<RouterOption>) -> Node {
            let isCaseInsensitive = options.contains(.caseInsensitive)
            
            switch component {
            case .constant(let string):
                // We're going to be comparing this path against an incoming losercased path later
                // so it's more efficient to lowercase it up front
                let string = (isCaseInsensitive) ? string.lowercased() : string
                // search for existing constant
                for constant in self.constants {
                    if constant.value == string {
                        return constant
                    }
                }
                
                // none found, add a new node
                let node = Node(value: string)
                self.constants.append(node)
                return node
            case .parameter(let string):
                let node: Node
                if let parameter = self.parameter {
                    node = parameter
                } else {
                    node = Node(value: string)
                    self.parameter = node
                }
                return node
            case .catchall:
                let node: Node
                if let fallback = self.catchall {
                    node = fallback
                } else {
                    node = Node(value: "*")
                    self.catchall = node
                }
                return node
            case .anything:
                let node: Node
                if let anything = self.anything {
                    node = anything
                } else {
                    node = Node(value: ":")
                    self.anything = node
                }
                return node
            }
        }
        
        var description: String {
            var desc: [String] = []
            desc.append("→ " + self.value)
            let children = self.constants + [self.parameter, self.catchall, self.anything].compactMap { $0 }
            for child in children {
                desc.append(child.description.indented())
            }
            return desc.joined(separator: "\n")
        }
    }
}

private extension String {
    func indented() -> String {
        return self.split(separator: "\n").map { line in
            return "  " + line
        }.joined(separator: "\n")
    }
}
