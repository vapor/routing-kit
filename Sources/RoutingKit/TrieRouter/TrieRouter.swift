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
    @inlinable public func route(path: [String], parameters: inout Parameters) -> Output? {
        var currentNode = self.root
        let isCaseInsensitive = self.options.contains(.caseInsensitive)
        var currentCatchall: (Node, [String])?

        search: for (index, slice) in path.enumerated() {
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
                    guard let match = slice.wholeMatch(of: partial.regex) else { continue }

                    for capture in match.output.dropFirst() {
                        guard let name = capture.name else { continue }
                        if let value = capture.value {
                            parameters.set(name, to: "\(value)")
                        }
                    }

                    currentNode = partial.node
                    continue search
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
}
