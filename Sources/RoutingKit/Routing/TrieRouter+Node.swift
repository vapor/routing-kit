import Foundation

extension TrieRouter {
    /// A single node of the `Router`s trie tree of routes.
    final class Node: CustomStringConvertible {
        /// All constant child nodes.
        var constants: [String: Node]
        
        /// Parameter child node, if one exists.
        var parameter: (String, Node)?
        
        /// Catchall node, if one exists.
        /// This node should not have any child nodes.
        var catchall: Node?
        
        /// Anything child node, if one exists.
        var anything: Node?
        
        /// This node's output
        var output: Output?
        
        /// Creates a new `RouterNode`.
        init(output: Output? = nil) {
            self.output = output
            self.constants = [String: Node]()
        }
        
        /// Fetches the child `RouterNode` for the supplied path component, or builds
        /// a new segment onto the tree if necessary.
        func buildOrFetchChild(for component: PathComponent, options: Set<RouterOption>) -> Node {
            let isCaseInsensitive = options.contains(.caseInsensitive)
            
            switch component {
            case .constant(let string):
                // We're going to be comparing this path against an incoming losercased path later
                // so it's more efficient to lowercase it up front
                let string = isCaseInsensitive ? string.lowercased() : string
                
                // search for existing constant
                if let node = self.constants[string] {
                    return node
                }
                
                // none found, add a new node
                let node = Node()
                self.constants[string] = node
                return node
            case .parameter(let string):
                let node: Node
                if let (name, existing) = self.parameter {
                    node = existing
                    assert(name == string, "router type mis-match \(name) != \(string)")
                } else {
                    node = Node()
                    self.parameter = (string, node)
                }
                return node
            case .catchall:
                let node: Node
                if let fallback = self.catchall {
                    node = fallback
                } else {
                    node = Node()
                    self.catchall = node
                }
                return node
            case .anything:
                let node: Node
                if let anything = self.anything {
                    node = anything
                } else {
                    node = Node()
                    self.anything = node
                }
                return node
            }
        }
        
        var description: String {
            var desc: [String] = []
            if let (name, parameter) = self.parameter {
                desc.append("→ \(name)")
                desc.append(parameter.description.indented())
            }
            if let catchall = self.catchall {
                desc.append("→ *")
                desc.append(catchall.description.indented())
            }
            if let anything = self.anything {
                desc.append("→ :")
                desc.append(anything.description.indented())
            }
            for (name, constant) in self.constants {
                desc.append("→ \(name)")
                desc.append(constant.description.indented())
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
