extension String {
    /// Calls `body` with a `Span` of this String's utf8 bytes.
    ///
    /// `UnnecessaryUnsafe` is used because Swift 6.3 requires it for `withContiguousStorageIfAvailable`.
    /// Swift 6.4 though has fixed this and we can remove the `UnnecessaryUnsafe` diagnostic.
    /// We can remove this when we drop support for Swift 6.3.
    #if swift(>=6.4)
        @diagnose(UnnecessaryUnsafe, as: ignored)
    #endif
    @inlinable
    func withSpanCompatibility<T>(_ body: (Span<UInt8>) -> T) -> T {
        /// Fast path: Currently always the case for non-Darwin.
        /// On Darwin, always the case unless for some objc-bridged strings.
        if let fastResult = unsafe self.utf8.withContiguousStorageIfAvailable({
            body(unsafe $0.span)
        }) {
            return fastResult
        }

        return self.withSpanCompatibilitySlowPath(body)
    }

    /// This function can only be reached on Darwin and only for some objc-bridged strings.
    /// Therefore it's not worth inlining. As a matter of fact it's worth not inlining it at all.
    @inline(never)
    @usableFromInline
    func withSpanCompatibilitySlowPath<T>(_ body: (Span<UInt8>) -> T) -> T {
        /// Same availability guard as `utf8Span` has in swift repo.
        /// The symbol is available there but will just abort.
        #if !(os(watchOS) && _pointerBitWidth(_32))
            if #available(SwiftStdlib 6.2, *) {
                return body(self.utf8Span.span)
            }
        #endif

        var copy = self
        return copy.withUTF8 {
            body(unsafe $0.span)
        }
    }
}

extension Substring {
    /// Calls `body` with a `Span` of this Substring's utf8 bytes.
    @inlinable
    func withSpanCompatibility<T>(_ body: (Span<UInt8>) -> T) -> T {
        /// Fast path: Currently always the case for non-Darwin.
        /// On Darwin, always the case unless for some objc-bridged strings.
        if let fastResult = unsafe self.utf8.withContiguousStorageIfAvailable({
            body(unsafe $0.span)
        }) {
            return fastResult
        }

        return self.withSpanCompatibilitySlowPath(body)
    }

    /// This function can only be reached on Darwin and only for some objc-bridged strings.
    /// Therefore it's not worth inlining. As a matter of fact it's worth not inlining it at all.
    @inline(never)
    @usableFromInline
    func withSpanCompatibilitySlowPath<T>(_ body: (Span<UInt8>) -> T) -> T {
        /// Same availability guard as `utf8Span` has in swift repo.
        /// The symbol is available there but will just abort.
        #if !(os(watchOS) && _pointerBitWidth(_32))
            if #available(SwiftStdlib 6.2, *) {
                return body(self.utf8Span.span)
            }
        #endif

        var copy = self
        return copy.withUTF8 {
            body(unsafe $0.span)
        }
    }
}
