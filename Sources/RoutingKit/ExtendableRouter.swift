public final class ExtendableRouter<Output>: Router {
    
    private var root: Node

    public init() {
        self.root = Node()
    }
    
    public func register(_ output: Output, at path: [PathComponent]) {
        
    }
    
    public func register(_ output: Output, at path: [RoutableComponent]) {
        var current = self.root
        for (index, component) in path.enumerated() {
            if component is CatchallComponent {
                precondition(index == path.count - 1, "Catchall ('\(component)') must be the last component in a path.")
            }
            current = current.buildOrFetchChild(for: component)
        }
        
        if current.output != nil {
            print("[Routing] Warning: Overriding route output at: \(path)")
        }
        
        current.output = output
    }
    
    public func route(path: [String], parameters: inout Parameters) -> Output? {
        return nil
    }
    
    public func route(context: inout RoutingContext) -> Output? {
        var currentCatchall: (Node, [String])?
                
        return self.route(&context, node: root, currentCatchall: &currentCatchall)
    }
    
    private func route(_ context: inout RoutingContext, node: Node, currentCatchall: inout (Node, [String])?) -> Output? {
        if let catchall = node.catchall {
            currentCatchall = (catchall, context.path.reversed())
        }
        
        for (subnode, component) in node.children.values {
//            print("x")
//            if component.check(context) {
//                return self.route(&context, node: subnode, currentCatchall: &currentCatchall)
//            }
        }
        
        if context.path.isEmpty {
            return node.output
        }
        
        // BELOW THIS IS WHERE THE SLOW PART IS
        
        if let pathComponent = context.popPathComponent() {
            if let (subnode, _) = node.constants[pathComponent] {
                return self.route(&context, node: subnode, currentCatchall: &currentCatchall)
            }
//
//            if let (paramName, paramNode, component) = node.parameter {
//                return self.route(&context, node: paramNode, currentCatchall: &currentCatchall)
//            }
//
//            if let (anything, anythingComponent) = node.anything {
//                return self.route(&context, node: anything, currentCatchall: &currentCatchall)
//            }
        }
        
        return nil
        
        if let (catchall, catchallPath) = currentCatchall {
            return catchall.output
        } else {
            return nil
        }
    }
}

extension ExtendableRouter {
    final class Node {
        var children: [String: (Node, RoutableComponent)]
        
        var constants: [String: (Node, ConstantComponent)]
        
        var parameter: (String, Node, ParameterComponent)?
        
        var catchall: Node?
        
        var anything: (Node, AnythingComponent)?
        
        var output: Output?
        
        init(output: Output? = nil) {
            self.output = output
            self.children = [:]
            self.constants = [:]
        }
        
        func buildOrFetchChild(for component: RoutableComponent) -> Node {
            if let component = component as? ParameterComponent {
                let node: Node
                if let (identifier, existingNode, _) = self.parameter {
                    assert(identifier == component.identifier, "Parameter name mismatch")
                    node = existingNode
                } else {
                    node = Node()
                    self.parameter = (component.identifier, node, component)
                }
                return node
            } else if let component = component as? AnythingComponent {
                let node: Node
                if let (existingAnything, _) = self.anything {
                    node = existingAnything
                } else {
                    node = Node()
                    self.anything = (node, component)
                }
                return node
            } else if component is CatchallComponent {
                let node: Node
                if let fallback = self.catchall {
                    node = fallback
                } else {
                    node = Node()
                    self.catchall = node
                }
                return node
                
            } else if let component = component as? ConstantComponent {
                if let (node, _) = self.constants[component.identifier] {
                    return node
                }
                
                let node = Node()
                self.constants[component.identifier] = (node, component)
                return node
            } else {
                if let (node, _) = self.children[component.identifier] {
                    return node
                }
                
                let node = Node()
                self.children[component.identifier] = (node, component)
                return node
            }
        }
        
        var description: String {
            self.subpathDescriptions.joined(separator: "\n")
        }
        
        var subpathDescriptions: [String] {
            var desc: [String] = []
            for (name, constant) in self.children {
                desc.append("→ \(name)")
                desc += constant.0.subpathDescriptions.indented()
            }
            for (name, constant) in self.constants {
                desc.append("→ \(name)")
                desc += constant.0.subpathDescriptions.indented()
            }
            if let (name, parameter, _) = self.parameter {
                desc.append("→ :\(name)")
                desc += parameter.subpathDescriptions.indented()
            }
            if let anything = self.anything {
                desc.append("→ *")
                desc += anything.0.subpathDescriptions.indented()
            }
            if let _ = self.catchall {
                desc.append("→ **")
            }
            return desc
        }
    }
}

private extension Array where Element == String {
    func indented() -> [String] {
        return self.map { "  " + $0 }
    }
}
