/// A type that can be passed as a path component to `TrieRouter.route(...)`.
public protocol RoutableComponent {
    /// Returns a `Parameter`'s value for this component.
    var routerParameterValue: String { get }

    /// Compares `self` to the bytes in the `UnsafeRawBufferPointer` according to specified options.
    /// - parameters:
    ///     - buffer: Bytes to compare self to.
    ///     - options: Router options to consider when comparing.
    /// - returns: `true` if `self` matches the supplied bytes.
    func routerCompare(to buffer: UnsafeRawBufferPointer, options: Set<RouterOption>) -> Bool
}

extension String: RoutableComponent {
    /// See `RoutableComponent`.
    public var routerParameterValue: String { return self }

    /// See `RoutableComponent`.
    public func routerCompare(to buffer: UnsafeRawBufferPointer, options: Set<RouterOption>) -> Bool {
        return Data(utf8).routerCompare(to: buffer, options: options)
    }
}

extension Data: RoutableComponent {
    /// See `RoutableComponent`.
    public var routerParameterValue: String {
        return String(data: self, encoding: .utf8) ?? ""
    }

    /// See `RoutableComponent`.
    public func routerCompare(to buffer: UnsafeRawBufferPointer, options: Set<RouterOption>) -> Bool {
        let a = self
        let b = buffer

        if a.count != b.count {
            return false
        }

        if options.contains(.caseInsensitive) {
            for i in 0..<a.count {
                if a[i] & 0xdf != b[i] & 0xdf {
                    return false
                }
            }
        } else {
            for i in 0..<a.count {
                if a[i] != b[i] {
                    return false
                }
            }
        }

        return true
    }
}
