extension String {
    /// Returns a `Span<UInt8>` over the underlying utf8-encoded bytes of this string.
    /// Does not modify the bytes despite being a `mutating` method.
    @usableFromInline
    mutating func withSpanCompatibility<T>(_ body: (Span<UInt8>) -> T) -> T {
        if let fastResult = self.utf8.withContiguousStorageIfAvailable({
            body(unsafe $0.span)
        }) {
            return fastResult
        }

        if #available(SwiftStdlib 6.2, *) {
            return body(self.utf8Span.span)
        }

        return self.withUTF8 {
            body(unsafe $0.span)
        }
    }
}

extension Substring {
    /// Returns a `Span<UInt8>` over the underlying utf8-encoded bytes of this substring.
    /// Does not modify the bytes despite being a `mutating` method.
    @usableFromInline
    mutating func withSpanCompatibility<T>(_ body: (Span<UInt8>) -> T) -> T {
        if let fastResult = unsafe self.utf8.withContiguousStorageIfAvailable({
            body(unsafe $0.span)
        }) {
            return fastResult
        }

        if #available(SwiftStdlib 6.2, *) {
            return body(self.utf8Span.span)
        }

        return self.withUTF8 {
            body(unsafe $0.span)
        }
    }
}
