import Foundation
import Logging

extension TrieRouter {
    internal func traverseBFS(
        fromPath: [String],
        visitOrder: @escaping ([NodeWithAbsolutePath]) -> [NodeWithAbsolutePath] = { $0 },
        shouldVisitNeighbours: @escaping (NodeWithAbsolutePath) -> Bool = { _ in return true },
        _ body: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows {
        guard let startNode = self.nodeForPath(fromPath) else {
            self.logger.debug("Attempted to traverse breadth-first a trie from a non-registered path \(fromPath)")
            return
        }
        
        let container = Queue<NodeWithAbsolutePath>()
        
        if let output = startNode.output {
            try body(fromPath, output)
        }
        
        var startingNeighbours = [NodeWithAbsolutePath]()
        
        for neighbour in startNode.constants.keys {
            guard let neighbourNode = startNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours in \(#file)")
                fatalError()
            }

            startingNeighbours.append(
                NodeWithAbsolutePath(
                    absolutePath: fromPath.appending(newElement: neighbour),
                    node: neighbourNode
                )
            )
        }
        
        for neighbour in visitOrder(startingNeighbours) {
            container.push(neighbour)
        }

        while !container.isEmpty {
            let nodeWithPath = container.pop()
            
            if let output = nodeWithPath.getNode().output {
                try body(nodeWithPath.getAbsolutePath(), output)
            }
        
            if shouldVisitNeighbours(nodeWithPath) {
                var neighbours = [NodeWithAbsolutePath]()
                
                for next in nodeWithPath.getNode().constants.keys {
                    guard let nextNode = nodeWithPath.getNode().constants[next] else {
                        self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours in \(#file)")
                        fatalError()
                    }
                    
                    neighbours.append(
                        NodeWithAbsolutePath(
                            absolutePath: nodeWithPath.getAbsolutePath().appending(newElement: next),
                            node: nextNode
                        )
                    )
                }
                
                for n in visitOrder(neighbours) {
                    container.push(n)
                }
            }
        }
    }
    
    public struct NodeWithAbsolutePath {
        private let absolutePath: [String]
        private let node: TrieRouter<Output>.Node
        
        fileprivate init(absolutePath: [String], node: TrieRouter<Output>.Node) {
            self.absolutePath = absolutePath
            self.node = node
        }
        
        public func getAbsolutePath() -> [String] {
            return self.absolutePath
        }
        
        internal func getNode() -> TrieRouter<Output>.Node {
            return self.node
        }
        
        public func getOutput() -> Output? {
            return self.node.output
        }
    }
}
