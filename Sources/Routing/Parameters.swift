public struct Parameters {
    public static let empty = Parameters(data: [:])
    public var data: [String: [String]]
}

extension Parameters {
    public mutating func next<P: Parameterizable>(_ p: P.Type = P.self) throws -> P {
        let error = ParametersError.noMoreParametersFound(forKey: P.uniqueSlug)
        guard var param = data[P.uniqueSlug] else {
            throw error
        }

        guard !param.isEmpty else {
            throw error
        }

        let rawValue = param.remove(at: 0)
        guard let value = rawValue.string else { throw error }

        data[P.uniqueSlug] = param
        return try P.make(for: value)
    }

    public subscript(_ key: String) -> [String]? {
        get { return data[key] }
        set { data[key] = newValue }
    }
}

public enum ParametersError: Swift.Error {
    case noMoreParametersFound(forKey: String)
}
