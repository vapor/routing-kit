import Foundation

extension TrieRouter {
    public func toDOT(
        _ transform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> String
    ) rethrows -> String {
        var DOTTree = String("digraph trie {\n")
        
        try self.forEachSlice { absolutePath, output in
            var neighboursList = String("{ ")
            
            if let neighbours = self.neighouringSlices(path: absolutePath) {
            
                for (offset, neighbour) in neighbours.enumerated() {
                    let nodeName = neighbour.getAbsolutePath().last != nil ?
                    try transform(
                        neighbour.getAbsolutePath(),
                        neighbour.getOutput()
                    ) : "root"
                    
                    neighboursList.append(
                        "\"\(nodeName)\"".appending(
                            offset >= neighbours.count - 1 ? "" : ", "
                        )
                    )
                }
                
                neighboursList.append(" }")
                
                let subgraphRootName = absolutePath.last != nil ?
                    try transform(absolutePath, output)
                        :
                "root"

                DOTTree = DOTTree.appending("""
                    "\(subgraphRootName)" -> \(neighboursList);\n
                """)
            }
        }
        
        DOTTree.append("}")
        
        return DOTTree
    }
    
}
