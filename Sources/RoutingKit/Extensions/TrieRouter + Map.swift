import Foundation

extension TrieRouter {
    
    public func mapBFS<T>(
        visitOrder: @escaping ([NodeWithAbsolutePath]) -> [NodeWithAbsolutePath] = { $0 },
        shouldVisitNeighbours: @escaping (NodeWithAbsolutePath) -> Bool = { _ in return true },
        _ transform: @escaping (_ absolutePath: [String], _ output: Output) throws -> T
    ) rethrows -> [T] {
        var mapped = [T]()
        
        try self.forEachBFS(visitOrder: visitOrder, shouldVisitNeighbours: shouldVisitNeighbours) { absolutePath, output in
            try mapped.append(transform(absolutePath, output))
        }
        
        return mapped
    }
    
    public func compactMapBFS<T>(
        visitOrder: @escaping ([NodeWithAbsolutePath]) -> [NodeWithAbsolutePath] = { $0 },
        shouldVisitNeighbours: @escaping (NodeWithAbsolutePath) -> Bool = { _ in return true },
        _ transform: @escaping (_ absolutePath: [String], _ output: Output) throws -> T?
    ) rethrows -> [T] {
        var mapped = [T]()
        
        try self.forEachBFS(visitOrder: visitOrder, shouldVisitNeighbours: shouldVisitNeighbours) { absolutePath, output in
            guard let transform = try transform(absolutePath, output) else { return }
            mapped.append(transform)
        }
        
        return mapped
    }
    
    public func map<T>(_ transform: @escaping (_ absolutePath: [String], _ output: Output) throws -> T) rethrows -> [T] {
        var mapped = [T]()
        
        try self.forEach { absolutePath, output in
            mapped.append(try transform(absolutePath, output))
        }
        
        return mapped
    }
    
    private func compactMap<T>(_ transform: @escaping (_ absolutePath: [String], _ output: Output) throws -> T?) rethrows -> [T] {
        var mapped = [T]()
        
        try self.forEach { absolutePath, output in
            let newElement = try transform(absolutePath, output)
            
            if let newElement = newElement {
                mapped.append(newElement)
            }
        }
        
        return mapped
    }
}


