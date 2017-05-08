import Node

public final class ParametersContext: Context {
    internal static let shared = ParametersContext()
    fileprivate init() {}
}

public let parametersContext = ParametersContext.shared

public struct Parameters: StructuredDataWrapper {
    public static var defaultContext: Context? = parametersContext
    public var wrapped: StructuredData
    public let context: Context
    
    public init(_ wrapped: StructuredData, in context: Context? = defaultContext) {
        self.wrapped = wrapped
        self.context = context ?? parametersContext
    }
}

extension Parameters {
    public func next<P: Parameterizable>(_ p: P.Type = P.self) throws -> P {
        let param = self[P.uniqueSlug]
        guard let next = param?.array?.first?.string ?? param?.string else {
            throw ParametersError.noMoreParametersFound(forKey: P.uniqueSlug)
        }
        return try P.make(for: next)
    }
}

public enum ParametersError: Swift.Error {
    case noMoreParametersFound(forKey: String)
}
