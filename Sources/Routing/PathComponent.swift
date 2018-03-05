import Foundation
import Bits

/// Components of a router path.
///
/// [Learn More →](https://docs.vapor.codes/3.0/routing/parameters/)
public enum DynamicPathComponent {
    /// A normal, constant path component.
    case constant(PathComponent)

    /// A dynamic parameter component.
    case parameter(PathComponent)
    
    /// Any set of components
    case anything
}

public struct PathComponent {
    let storage: PathComponentStorage

    public init(data: Data) {
        self.storage = .data(data)
    }

    public init(bytes: [UInt8]) {
        self.storage = .bytes(bytes)
    }

    public init(bytes: BytesBufferPointer) {
        self.storage = .bytesBufferPointer(bytes)
    }

    public init(bytes: ByteBuffer) {
        self.storage = .byteBuffer(bytes)
    }

    public init(string: String) {
        self.storage = .string(string)
    }

    public init(substring: Substring) {
        self.storage = .substring(substring)
    }

    public var count: Int {
        switch storage {
        case .data(let data): return data.count
        case .bytesBufferPointer(let buffer): return buffer.count
        case .byteBuffer(let byteBuffer): return byteBuffer.readableBytes
        case .bytes(let bytes): return bytes.count
        case .string(let string): return string.utf8.count
        case .substring(let substring): return substring.utf8.count
        }
    }

    func withByteBuffer<T>(do closure: (BytesBufferPointer) -> (T)) -> T {
        switch storage {
        case .data(let data): return data.withByteBuffer(closure)
        case .bytesBufferPointer(let buffer): return closure(buffer)
        case .byteBuffer(let byteBuffer): return byteBuffer.withUnsafeReadableBytes { raw -> T in
            return closure(raw.bindMemory(to: Byte.self))
            }
        case .bytes(let bytes): return bytes.withUnsafeBufferPointer(closure)
        case .string(let string):
            let count = self.count

            return string.withCString { pointer in
                return pointer.withMemoryRebound(to: UInt8.self, capacity: count) { pointer in
                    return closure(BytesBufferPointer(start: pointer, count: count))
                }
            }
        case .substring(let substring):
            let count = self.count

            return substring.withCString { pointer in
                return pointer.withMemoryRebound(to: UInt8.self, capacity: count) { pointer in
                    return closure(BytesBufferPointer(start: pointer, count: count))
                }
            }
        }
    }

    public var string: String {
        switch storage {
        case .string(let string): return string
        default:
            return String(bytes: self.bytes, encoding: .utf8) ?? ""
        }
    }

    public var bytes: [UInt8] {
        switch storage {
        case .data(let data): return Array(data)
        case .bytesBufferPointer(let buffer): return Array(buffer)
        case .byteBuffer(var byteBuffer): return byteBuffer.readBytes(length: byteBuffer.readableBytes) ?? []
        case .bytes(let bytes): return bytes
        case .string(let string): return [UInt8](string.utf8)
        case .substring(let substring): return Array(substring.utf8)
        }
    }
}

enum PathComponentStorage {
    case data(Data)
    case bytes([UInt8])
    case bytesBufferPointer(BytesBufferPointer)
    case byteBuffer(ByteBuffer)
    case string(String)
    case substring(Substring)
}

/// Capable of being represented by dynamic path components.
///
/// [Learn More →](https://docs.vapor.codes/3.0/routing/parameters/)
public protocol DynamicPathComponentRepresentable {
    /// Convert to path component.
    func makeDynamicPathComponents() -> [DynamicPathComponent]
}

extension DynamicPathComponent: DynamicPathComponentRepresentable {
    /// See `DynamicPathComponentRepresentable.makeDynamicPathComponents()`
    public func makeDynamicPathComponents() -> [DynamicPathComponent] {
        return [self]
    }
}

extension Array where Element == DynamicPathComponentRepresentable {
    /// See `DynamicPathComponentRepresentable.makeDynamicPathComponents()`
    public func makeDynamicPathComponents() -> [DynamicPathComponent] {
        return flatMap { $0.makeDynamicPathComponents() }
    }
}

extension String: DynamicPathComponentRepresentable {
    /// See `DynamicPathComponentRepresentable.makeDynamicPathComponents()`
    public func makeDynamicPathComponents() -> [DynamicPathComponent] {
        return split(separator: "/").map { .constant(.init(substring: $0)) }
    }
}
