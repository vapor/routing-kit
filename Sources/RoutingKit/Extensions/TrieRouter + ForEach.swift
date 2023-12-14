import Foundation

extension TrieRouter {
    
    public func forEachBFS(
        visitOrder: @escaping ([NodeWithAbsolutePath]) -> [NodeWithAbsolutePath] = { $0 },
        shouldVisitNeighbours: @escaping (NodeWithAbsolutePath) -> Bool = { _ in return true },
        _ body: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        return try self.traverseBFS(
            fromPath: [],
            visitOrder: visitOrder,
            shouldVisitNeighbours: shouldVisitNeighbours,
            body
        )
    }
    
    public func forEach(_ body: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void) rethrows {
        try self.traverseInit(perform: body)
    }
    
    public func forEachSlice(_ body: @escaping (_ absolutePath: [String], _ output: Output?) throws -> Void) rethrows {
        try self.traverseAllNodesInit(perform: body)
    }
    
    // MARK: - TRAVERSE ONLY CONSTANT ROUTES WITH AN ASSOCIATED OUTPUT
    private func traverseInit(
        path: [String] = [],
        perform: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        let currentNode = self.nodeForPath(path)
        guard let currentNode = currentNode else { return }
        
        try traverse(rootNode: currentNode, path: path, perform: perform)
    }
    
    private func traverse(
        rootNode: TrieRouter<Output>.Node,
        path: [String],
        perform: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        if let output = rootNode.output {
            try perform(path, output)
        }

        for neighbour in rootNode.constants.keys {
            guard let neighbourNode = rootNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours in \(#file)")
                fatalError()
            }
            
            try traverse(rootNode: neighbourNode, path: path.appending(newElement: neighbour), perform: perform)
        }
    }
    
    // MARK: - TRAVERSE ALL ROUTES, WITH OR WITHOUT ASSOCIATED OUTPUT
    private func traverseAllNodesInit(
        path: [String] = [],
        perform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> Void
    ) rethrows {
        let currentNode = self.nodeForPath(path)
        guard let currentNode = currentNode else { return }
        
        try traverseAllNodes(rootNode: currentNode, path: path, perform: perform)
    }
    
    private func traverseAllNodes(
        rootNode: TrieRouter<Output>.Node,
        path: [String],
        perform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> Void
    ) rethrows {
        try perform(path, rootNode.output)

        for neighbour in rootNode.constants.keys {
            guard let neighbourNode = rootNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours in \(#file)")
                fatalError()
            }
            
            try traverse(rootNode: neighbourNode, path: path.appending(newElement: neighbour), perform: perform)
        }
    }
    
    internal func traverse(
        rootNode: TrieRouter<Output>.Node,
        path: [String],
        perform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> Void
    ) rethrows {
        try perform(path, rootNode.output)

        for neighbour in rootNode.constants.keys {
            guard let neighbourNode = rootNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours in \(#file)")
                fatalError()
            }
            
            try traverse(rootNode: neighbourNode, path: path.appending(newElement: neighbour), perform: perform)
        }
    }
    
    internal func nodeForPath(_ path: [String]) -> TrieRouter<Output>.Node? {
        var currentNode: Node = self.root
    
        let isCaseInsensitive = self.options.contains(.caseInsensitive)

        for slice in path {
            if let constant = currentNode.constants[isCaseInsensitive ? slice.lowercased() : slice] {
                currentNode = constant
            } else {
                return nil
            }
        }

        return currentNode
    }
}
