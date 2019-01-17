import Foundation

/// A type that can be created from `Data` in a lossless, unambiguous way.
public protocol LosslessDataConvertible {
    /// Losslessly converts `Data` to this type.
    init?(_ data: Data)
}

public extension LosslessDataConvertible {
    init?(_ data: Data) {
        guard data.count < MemoryLayout<Self>.size else {
            return nil
        }
        self = data.withUnsafeBytes { $0.pointee }
    }
}

/// A type that can be converted to `Data`
public protocol CustomDataConvertible {
    /// Losslessly converts this type to `Data`.
    func convertToData() -> Data
}

extension Data {
    /// Converts this `Data` to a `LosslessDataConvertible` type.
    ///
    ///     let string = Data([0x68, 0x69]).convert(to: String.self)
    ///     print(string) // "hi"
    ///
    /// - parameters:
    ///     - type: The `LosslessDataConvertible` to convert to.
    /// - returns: Instance of the `LosslessDataConvertible` type.
    public func convert<T>(to type: T.Type = T.self) -> T? where T: LosslessDataConvertible {
        return T.init(self)
    }
}

extension String: LosslessDataConvertible, CustomDataConvertible {
    /// Converts this `String` to data using `.utf8`.
    public func convertToData() -> Data {
        return Data(utf8)
    }
    
    /// Converts `Data` to a `utf8` encoded String.
    ///
    /// - throws: Error if String is not UTF8 encoded.
    public init?(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            /// FIXME: string convert _from_ data is not actually lossless.
            /// this should really only conform to a `LosslessDataRepresentable` protocol.
            return nil
        }
        self = string
    }
}


/// A single path component of a `Route`. An array of these components describes
/// a route's path, including which parts are constant and which parts are dynamic (parameters).
public enum PathComponent: ExpressibleByStringLiteral {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component.
    case parameter(String, LosslessDataConvertible.Type)
    
    /// This route will match everything that is not in other routes
    case anything
    
    /// This route will match and discard any number of constant components after
    /// this anything component.
    case catchall

    /// See `ExpressibleByStringLiteral`.
    public init(stringLiteral value: String) {
        self = .constant(value)
    }
}

/// Shortcut for accessing `PathComponent.anything`.
public let any: PathComponent = .anything
/// Shortcut for accessing `PathComponent.catchall`.
public let all: PathComponent = .catchall


extension Array where Element == PathComponent {
    /// Creates a readable representation of this array of `PathComponent`.
    public var readable: String {
        return "/" + map {
            switch $0 {
            case .constant(let s): return s
            case .parameter(let p): return ":\(p)"
            case .anything: return ":"
            case .catchall: return "*"
            }
        }.joined(separator: "/")
    }
}

/// Capable of being represented by an array of `PathComponent`.
public protocol PathComponentsRepresentable {
    /// Converts self to an array of `PathComponent`.
    func convertToPathComponents() -> [PathComponent]
}

extension PathComponent: PathComponentsRepresentable {
    /// See `PathComponentsRepresentable`.
    public func convertToPathComponents() -> [PathComponent] {
        return [self]
    }
}

extension String: PathComponentsRepresentable {
    /// See `PathComponentsRepresentable`.
    public func convertToPathComponents() -> [PathComponent] {
        return split(separator: "/").map { .constant(.init($0)) }
    }
}

extension Array: PathComponentsRepresentable where Element == PathComponentsRepresentable {
    /// Converts self to an array of `PathComponent`.
    public func convertToPathComponents() -> [PathComponent] {
        return flatMap { $0.convertToPathComponents() }
    }
}
