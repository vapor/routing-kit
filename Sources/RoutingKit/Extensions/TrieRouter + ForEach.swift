import Foundation
import Logging

extension TrieRouter {
    
    public func forEachBFS(
        rootPath: [String] = [],
        visitOrder: @escaping ([NodeWithAbsolutePath]) -> [NodeWithAbsolutePath] = { $0 },
        shouldVisitNeighbours: @escaping (NodeWithAbsolutePath) -> Bool = { _ in return true },
        _ body: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        return try self.traverseBFS(
            fromPath: rootPath,
            visitOrder: visitOrder,
            shouldVisitNeighbours: shouldVisitNeighbours,
            body
        )
    }
    
    public func forEach(
        rootPath: [String] = [],
        _ body: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        try self.traverseInit(path: rootPath, perform: body)
    }
    
    public func forEachSlice(
        rootPath: [String] = [], 
        _ body: @escaping (_ absolutePath: [String], _ output: Output?) throws -> Void
    ) rethrows {
        try self.traverseAllNodesInit(path: rootPath, perform: body)
    }
    
    // MARK: - TRAVERSE ONLY CONSTANT ROUTES WITH AN ASSOCIATED OUTPUT
    private func traverseInit(
        path: [String] = [],
        perform: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        let currentNode = self.nodeForPath(path)
        guard let currentNode = currentNode else {
            self.logger.debug("Attempted to topologically traverse a trie from a non-registered path \(path).")
            return
        }
        
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
        guard let currentNode = currentNode else {
            self.logger.debug("Attempted to topologically traverse (all slices of) a trie from a non-registered path \(path).")
            return
        }
        
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
