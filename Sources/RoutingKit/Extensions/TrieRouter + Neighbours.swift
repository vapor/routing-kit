import Foundation
import Logging

public extension TrieRouter {
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter path: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    internal func neighbours(path: [String]) -> [OutputWithPath]? {
        guard let currentNode = nodeForPath(path) else {
            self.logger.debug("Attempted to extract neighbours of unregistered path \(path).")
            return nil
        }
        
        var neighbours: [OutputWithPath] = []
        
        for neighbour in currentNode.constants.keys {
            guard let neighbouringNode = currentNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours of \(neighbour)")
                fatalError()
            }
            
            if let output = neighbouringNode.output {
                var absolutePath = path
                absolutePath.append(neighbour)
                                
                neighbours.append(
                    OutputWithPath(
                        output: output,
                        absolutePath: absolutePath
                    )
                )
            }
        }
        
        return neighbours
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter parentPath: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    func forEachNeighbour(
        parentPath: [String],
        _ body: @escaping (_ absolutePath: [String], _ output: Output) throws -> Void
    ) rethrows -> Void {
        guard let neighbours = self.neighbours(path: parentPath) else {
            return
        }
        
        try neighbours.forEach { neighbour in
            try body(neighbour.getAbsolutePath(), neighbour.getOutput())
        }
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter parentPath: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Note: If `parentPath` is a valid registered path of constants, the output is safe to unwrap.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    func mapNeighbours<T>(
        parentPath: [String],
        _ transform: @escaping (_ absolutePath: [String], _ output: Output) throws -> T
    ) rethrows -> [T]? {
        guard let neighbours = self.neighbours(path: parentPath) else {
            return nil
        }
        
        var mapped = [T].init()
        
        try neighbours.forEach { neighbours in
            mapped.append(try transform(neighbours.getAbsolutePath(), neighbours.getOutput()))
        }
        
        return mapped
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter parentPath: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Note: If `parentPath` is a valid registered path of constants, the output is safe to unwrap.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    func compactMapNeighbours<T>(
        parentPath: [String],
        _ transform: @escaping (_ absolutePath: [String], _ output: Output) throws -> T?
    ) rethrows -> [T]? {
        guard let neighbours = self.neighbours(path: parentPath) else {
            return nil
        }
        
        var mapped = [T].init()
        
        try neighbours.forEach { neighbours in
            if let transformed = try transform(neighbours.getAbsolutePath(), neighbours.getOutput()) {
                mapped.append(transformed)
            }
        }
        
        return mapped
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter path: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    internal func neighouringSlices(path: [String]) -> [NullableOutputWithPath]? {
        guard let currentNode = nodeForPath(path) else {
            self.logger.debug("Attempted to extract neighbouring slices of unregistered path \(path).")
            return nil
        }
        
        var neighbours: [NullableOutputWithPath] = []
        for neighbour in currentNode.constants.keys {
            guard let neighbouringNode = currentNode.constants[neighbour] else {
                self.logger.error("Unexpectedly found missing neighbour while exploring node neighbours")
                fatalError()
            }
            
            var absolutePath = path
            absolutePath.append(neighbour)
                            
            neighbours.append(
                NullableOutputWithPath(
                    output: neighbouringNode.output,
                    absolutePath: absolutePath
                )
            )
        }
        
        return neighbours
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter parentPath: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    func forEachNeighbouringSlice(
        parentPath: [String],
        _ body: @escaping (_ absolutePath: [String], _ output: Output?) throws -> Void
    ) rethrows -> Void {
        guard let neighbouringSlices = self.neighouringSlices(path: parentPath) else {
            return
        }
        
        try neighbouringSlices.forEach { neighbour in
            try body(neighbour.getAbsolutePath(), neighbour.getOutput())
        }
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter parentPath: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Note: If `parentPath` is a valid path of constants, the output is safe to unwrap.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    func mapNeighbouringSlices<T>(
        parentPath: [String],
        _ transform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> T
    ) rethrows -> [T]? {
        guard let neighbouringSlices = self.neighouringSlices(path: parentPath) else {
            return nil
        }
        
        var mapped = [T].init()
        
        try neighbouringSlices.forEach { neighbour in
            mapped.append(try transform(neighbour.getAbsolutePath(), neighbour.getOutput()))
        }
        
        return mapped
    }
    
    /// Fetches all the neighbours for the specified path, if it exists.
    /// - Parameter parentPath: The path to match against. If empty, it returns the neighbours of the root node with an associated output.
    ///
    /// - Note: If `parentPath` is a valid path of constants, the output is safe to unwrap.
    ///
    /// - Complexity: O(path.count + constants.count) to fetch the path and filter out the neighbours with no associated output in the router
    func compactMapNeighbouringSlices<T>(
        parentPath: [String],
        _ transform: @escaping (_ absolutePath: [String], _ output: Output?) throws -> T?
    ) rethrows -> [T]? {
        guard let neighbouringSlices = self.neighouringSlices(path: parentPath) else {
            return nil
        }
        
        var mapped = [T].init()
        
        try neighbouringSlices.forEach { neighbour in
            if let transformed = try transform(neighbour.getAbsolutePath(), neighbour.getOutput()) {
                mapped.append(transformed)
            }
        }
        
        return mapped
    }
    
    func reduceNeighbours<T>(
        parentPath: [String] = [],
        _ initialValue: @autoclosure () -> T,
        _ transform: @escaping (_ partialResult: T, _ absolutePath: [String], _ output: Output) throws -> T
    ) rethrows -> T {
        var partial = initialValue()
        
        try self.forEachNeighbour(parentPath: parentPath) { absolutePath, output in
            partial = try transform(partial, absolutePath, output)
        }
        
        return partial
    }
}
