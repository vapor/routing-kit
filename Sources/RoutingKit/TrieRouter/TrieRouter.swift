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
    ///
    /// This is an `OptionSet`-style type so additional options can be added via
    /// extensions without changing the public API surface.
    public struct Configuration: Sendable {
        public let isCaseInsensitive: Bool

        public init(isCaseInsensitive: Bool = false) {
            self.isCaseInsensitive = isCaseInsensitive
        }

        public static var caseInsensitive: Self { .init(isCaseInsensitive: true) }
    }

    @usableFromInline
    let root: Node

    @usableFromInline
    let config: Configuration

    init(builder: TrieRouterBuilder<Output>) {
        self.root = builder.root
        self.config = builder.config
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
        let isCaseInsensitive = self.config.isCaseInsensitive
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
                            parameters.set(String(name), to: String(value))
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
        } else if path.isEmpty, let catchall = currentNode.catchall {
            parameters.setCatchall(matched: [])
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
    func isMatchForPartial(partial: Node.PartialMatch, path: String, parameters: Parameters) -> [Substring: Substring]? {
        var result: [Substring: Substring] = [:]
        var index = path.startIndex

        var componentIndex = partial.components.startIndex
        let lastComponentIndex = partial.components.index(before: partial.components.endIndex)

        while componentIndex <= lastComponentIndex {
            if index >= path.endIndex {
                // If we're at the end but there are more components, fail
                if componentIndex < lastComponentIndex { return nil }
                break
            }

            let element = partial.components[componentIndex]

            if element.isEmpty {
                let endIndex: String.Index
                if componentIndex < lastComponentIndex {
                    let nextElement = partial.components[partial.components.index(after: componentIndex)]
                    // greedy matching
                    guard let range = path.range(of: nextElement, options: .backwards, range: index..<path.endIndex) else { return nil }
                    endIndex = range.lowerBound
                } else {
                    endIndex = path.endIndex
                }
                result[partial.parameters[result.count]] = path[index..<endIndex]
                index = endIndex
            } else {
                // Verify the literal matches at current position
                let substring = path[index...].prefix(element.count)
                guard substring == element else { return nil }
                index = substring.endIndex
            }

            partial.components.formIndex(after: &componentIndex)
        }

        return result
    }
}
