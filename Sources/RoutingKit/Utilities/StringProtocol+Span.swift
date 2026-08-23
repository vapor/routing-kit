extension String {
    /// Returns a `Span<UInt8>` over the underlying utf8-encoded bytes of this string.
    @usableFromInline
    func withSpanCompatibility<T>(_ body: (Span<UInt8>) -> T) -> T {
        if let fastResult = self.utf8.withContiguousStorageIfAvailable({
            body(unsafe $0.span)
        }) {
            return fastResult
        }

        if #available(SwiftStdlib 6.2, *) {
            return body(self.utf8Span.span)
        }

        var copy = self
        return copy.withUTF8 {
            body(unsafe $0.span)
        }
    }
}

extension Substring {
    /// Returns a `Span<UInt8>` over the underlying utf8-encoded bytes of this substring.
    @usableFromInline
    func withSpanCompatibility<T>(_ body: (Span<UInt8>) -> T) -> T {
        if let fastResult = unsafe self.utf8.withContiguousStorageIfAvailable({
            body(unsafe $0.span)
        }) {
            return fastResult
        }

        if #available(SwiftStdlib 6.2, *) {
            return body(self.utf8Span.span)
        }

        var copy = self
        return copy.withUTF8 {
            body(unsafe $0.span)
        }
    }
}
