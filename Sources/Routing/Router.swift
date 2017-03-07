internal typealias Host = String
internal typealias Method = String

// MARK: Router

/**
    A simple, flexible, and efficient HTTP Router built on top of Branches
 
    Output represents the object, closure, etc. that the router should be registering and returning
*/
public class Router<Output> {

    // MARK: Private Tree Representation

    internal final let base = Branch<Output>(name: "", output: nil)

    // MARK: Init

    /**
        Base Initializer
    */
    public init() {}

    /// Register a given path. Use `*` for host OR method to define wildcards that will be matched
    /// if no concrete match exists.
    ///
    /// - parameter host: the host to match, ie: '0.0.0.0', or `*` to match any
    /// - parameter method: the method to match, ie: `GET`, or `*` to match any
    ///     - parameter path: the path that should be registered
    /// - parameter output: the associated output of this path, usually a responder, or `nil`
    public func register(path: [String], output: Output?) {
        let path = path.filter { !$0.isEmpty }
        base.extend(path, output: output)
    }

    // MARK: Route

    /**
        Routes an incoming path, filling the parameters container
        with any found parameters.
     
        If an Output is found, it is returned.
    */
    public func route(path: [String], with container: ParametersContainer) -> Output? {
        let path = path.filter { !$0.isEmpty }
        let result = base.fetch(path)
        container.parameters = result?.branch.slugs(for: path) ?? [:]
        guard let output = result?.branch.output else {
            return nil
        }
        return output
    }
}
