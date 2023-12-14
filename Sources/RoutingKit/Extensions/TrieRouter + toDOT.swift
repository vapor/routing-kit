import Foundation

extension TrieRouter {
    public func toDOT(
        rootPath: [String] = [],
        _ transform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> String
    ) rethrows -> String {
        let root = nodeForPath(rootPath)
        var DOTTree = String("digraph trie { ")
        
        try self.forEachSlice { absolutePath, output in
            var neighboursList = String("{ ")
            
            if let neighbours = self.neighouringSlices(path: absolutePath) {
            
                for (offset, neighbour) in neighbours.enumerated() {
                    neighboursList.append(
                        try transform(
                            neighbour.getAbsolutePath(),
                            neighbour.getOutput()
                        ).appending(
                            offset >= neighbours.count - 1 ? "" : ","
                        )
                    )
                }
                neighboursList.append(" } ")
                
                
                DOTTree = DOTTree.appending("""
                    \(try transform(absolutePath, output)) -> \(neighboursList);
                """)
            }
        }
        
        DOTTree.append("}")
        
        return DOTTree
    }
    
}
