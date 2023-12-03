import Foundation

extension TrieRouter {
    
    public func forEachBFS(
        visitOrder: @escaping ([NodeWithAbsolutePath]) -> [NodeWithAbsolutePath] = { $0 },
        shouldVisitNeighbours: @escaping (NodeWithAbsolutePath) -> Bool = { _ in return true },
        _ body: @escaping (_ absolutePath: [String], _ output: Output) -> Void
    ) {
        return self.traverseBFS(
            fromPath: [],
            visitOrder: visitOrder,
            shouldVisitNeighbours: shouldVisitNeighbours,
            body
        )
    }
    
    public func forEach(_ body: @escaping (_ absolutePath: [String], _ output: Output) -> Void) {
        self.traverseInit(perform: body)
    }
    
    private func traverseInit(
        path: [String] = [],
        perform: @escaping (_ absolutePath: [String], _ output: Output) -> Void
    ) {
        let currentNode = self.nodeForPath(path)
        guard let currentNode = currentNode else { return }
        
        traverse(rootNode: currentNode, path: path, perform: perform)
    }
    
    private func traverse(
        rootNode: TrieRouter<Output>.Node,
        path: [String],
        perform: @escaping (_ absolutePath: [String], _ output: Output) -> Void
    ) {
        if let output = rootNode.output {
            perform(path, output)
        }

        for neighbour in rootNode.constants.keys {
            guard let neighbourNode = rootNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours in \(#file)")
                fatalError()
            }
            
            traverse(rootNode: neighbourNode, path: path.appending(newElement: neighbour), perform: perform)
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
