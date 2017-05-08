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
    func get<P: Parameterizable>(_ p: P.Type = P.self) throws -> P {
        let parameter = try get(P.uniqueSlug) as String
        return try P.make(for: parameter)s
    }
}
