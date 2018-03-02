import Foundation

/// A parameter and its resolved value.
public struct ParameterValue {
    /// The resolved value.
    let value: [UInt8]

    /// Create a new lazy parameter.
    init(value: [UInt8]) {
        self.value = value
    }
}
