public import Algorithms
import Foundation
import Logging

/// Generic ``TrieRouter`` built using the "trie" tree algorithm.
///
/// Use ``register(_:at:)`` to register routes into the router. Use ``route(path:parameters:)`` to then fetch
/// a matching route's output.
///
/// See https://en.wikipedia.org/wiki/Trie for more information.
public final class TrieRouter<Output: Sendable>: Router, Sendable, CustomStringConvertible {
    @usableFromInline typealias Node = TrieRouterNode<Output>

    /// Available ``TrieRouter`` customization options.
    public enum ConfigurationOption: Sendable {
        /// If set, this will cause the router's route matching to be case-insensitive.
        ///
        /// > Note: Case-insensitive routing may be less performant than case-sensitive routing.
        case caseInsensitive
    }

    @usableFromInline
    let root: Node

    @usableFromInline
    let options: Set<ConfigurationOption>

    init(builder: TrieRouterBuilder<Output>) {
        self.root = builder.root
        self.options = builder.options
    }

    /// Routes a path, returning the best-matching output and collecting any dynamic parameters.
    ///
    ///     var params = Parameters()
    ///     router.route(path: ["users", "Vapor"], parameters: &params)
    ///
    /// - Parameters:
    ///   - path: Raw path segments.
    ///   - parameters: Will collect dynamic parameter values.
    /// - Returns: Output of matching route, if found.
    @inlinable
    public func route(path: [String], parameters: inout Parameters) -> Output? {
        var currentNode = self.root
        let isCaseInsensitive = self.options.contains(.caseInsensitive)
        var currentCatchall: (Node, [String])?

        search: for (index, slice) in path.indexed() {
            if let catchall = currentNode.catchall {
                currentCatchall = (catchall, [String](path.dropFirst(index)))
            }

            if let constant = currentNode.constants[isCaseInsensitive ? slice.lowercased() : slice] {
                currentNode = constant
                continue search
            }

            if let wildcard = currentNode.wildcard {
                if let name = wildcard.parameter {
                    parameters.set(name, to: slice)
                }

                currentNode = wildcard.node
                continue search
            }

            if let partials = currentNode.partials, !partials.isEmpty {
                for partial in partials {
                    if let captures = isMatchForPartial(partial: partial, path: slice, parameters: parameters) {
                        for (name, value) in captures {
                            parameters.set(String(name), to: value)
                        }
                        currentNode = partial.node
                        continue search
                    }
                }
            }

            if let (catchall, subpaths) = currentCatchall {
                parameters.setCatchall(matched: subpaths)
                return catchall.output
            } else {
                return nil
            }
        }

        if let output = currentNode.output {
            return output
        } else if let (catchall, subpaths) = currentCatchall {
            parameters.setCatchall(matched: subpaths)
            return catchall.output
        } else {
            return nil
        }
    }

    // See `CustomStringConvertible.description`.
    public var description: String {
        self.root.description
    }

    @usableFromInline
    func isMatchForPartial(partial: Node.PartialMatch, path: String, parameters: Parameters) -> [Substring: String]? {
        var result: [Substring: String] = [:]
        var index = path.startIndex
        var parametersIndex = 0

        let componentsCount = partial.components.count
        var componentIndex = 0

        while componentIndex < componentsCount {
            if index >= path.endIndex {
                // If we're at the end but there are more components, fail
                if componentIndex != componentsCount - 1 { return nil }
                break
            }

            let element = partial.components[componentIndex]

            if element.isEmpty {
                let endIndex: String.Index
                if componentIndex + 1 < componentsCount {
                    let nextElement = partial.components[componentIndex + 1]
                    // greedy matching
                    guard let range = path.range(of: nextElement, options: .backwards, range: index..<path.endIndex) else { return nil }
                    endIndex = range.lowerBound
                } else {
                    endIndex = path.endIndex
                }
                result[partial.parameters[parametersIndex]] = String(path[index..<endIndex])
                parametersIndex += 1
                index = endIndex
            } else {
                // Verify the literal matches at current position
                let expectedEnd = path.index(index, offsetBy: element.count, limitedBy: path.endIndex)
                guard
                    let endPos = expectedEnd,
                    path[index..<endPos] == element
                else { return nil }
                index = endPos
            }

            componentIndex += 1
        }

        return result
    }
}
