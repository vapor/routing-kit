/// A bag for holding parameters resolved during router
public struct ParameterBag {
    /// The parameters
     var parameters: [LazyParameter]

    /// Create a new parameters bag
    public init() {
        self.parameters = []
    }

    public mutating func next<P: Parameter>(_ parameter: P.Type = P.self) throws -> P {
        guard parameters.count > 0 else {
            throw "no params"
        }
        let current = parameters[0]

        guard current.type == P.self else {
            throw "incorrect type"
        }

        let item = try current.type.make(for: current.value)
        guard let cast = item as? P else {
            throw "incorrect type"
        }

        parameters = Array(parameters.dropFirst())

        return cast
    }
}

internal struct LazyParameter {
    let type: Parameter.Type
    let value: String

    init(type: Parameter.Type, value: String) {
        self.type = type
        self.value = value
    }
}

extension String: Error {}
