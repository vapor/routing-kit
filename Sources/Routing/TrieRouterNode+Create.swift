extension TrieRouterNode {
    fileprivate func find(constant: String) -> TrieRouterNode<Output> {
        let node: TrieRouterNode<Output>
        
        if let found = self.findConstant(constant) {
            node = found
        } else {
            node = TrieRouterNode<Output>(kind: .constant(data: [UInt8](constant.utf8), dataSize: constant.count))
            self.children.append(node)
        }

        return node
    }
    
    fileprivate func find(component: DynamicPathComponent) -> TrieRouterNode<Output> {
        switch component {
        case .constant(let constant):
            return self.find(constant: constant.string)
        case .parameter(let p):
            if let node = self.findParameterNode() {
                return node
            } else {
                let node = TrieRouterNode<Output>(kind: .parameter(data: p.bytes))
                self.children.append(node)
                return node
            }
        case .anything:
            if let node = findAnyNode() {
                return node
            } else {
                let node = TrieRouterNode<Output>(kind: .anything)
                self.children.append(node)
                return node
            }
        }
    }
    
    /// Returns the first parameter node
    fileprivate func findParameterNode() -> TrieRouterNode<Output>? {
        for child in children {
            if case .parameter = child.kind {
                return child
            }
        }
        
        return nil
    }
    
    func findConstant(_ buffer: String) -> TrieRouterNode? {
        for child in children {
            if case .constant(let data, _) = child.kind, data == [UInt8](buffer.utf8) {
                return child
            }
        }
        
        return nil
    }
    
    fileprivate func findAnyNode() -> TrieRouterNode? {
        for child in children {
            if case .anything = child.kind {
                return child
            }
        }
        
        return nil
    }
    
    subscript(path: DynamicPathComponent) -> TrieRouterNode<Output> {
        return self.find(component: path)
    }
}
