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
    public mutating func next<P: Parameterizable>(_ p: P.Type = P.self) throws -> P {
        let error = ParametersError.noMoreParametersFound(forKey: P.uniqueSlug)
        guard let param = self[P.uniqueSlug] else { throw error }

        var array = param.array ?? [param]
        guard !array.isEmpty else { throw error }

        let rawValue = array.remove(at: 0)
        guard let value = rawValue.string else { throw error }

        self[P.uniqueSlug] = .array(array)
        return try P.make(for: value)
    }
}

public enum ParametersError: Swift.Error {
    case noMoreParametersFound(forKey: String)
}
