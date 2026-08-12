extension String {
    /// Byte-literal backwards search, equivalent to
    /// `range(of: needle, options: [.backwards, .literal], range:)`
    /// over UTF-8 offsets.
    func lastUTF8Range(of needle: Substring, in searchRange: Range<Int>) -> Range<Int>? {
        let haystack = self.utf8.span
        let pattern = needle.utf8.span
        let n = pattern.count

        guard
            n > 0, searchRange.count >= n,
            searchRange.upperBound <= haystack.count
        else { return nil }

        let first = pattern[0]
        var start = searchRange.upperBound - n

        while start >= searchRange.lowerBound {
            if haystack[start] == first {
                var k = 1
                while k < n, haystack[start + k] == pattern[k] { k += 1 }
                if k == n { return start..<start + n }
            }
            start -= 1
        }
        return nil
    }

    func range(
        of needle: Substring,
        backwardsIn searchRange: Range<String.Index>
    ) -> Range<String.Index>? {
        let utf8 = self.utf8
        let lower = utf8.distance(from: utf8.startIndex, to: searchRange.lowerBound)
        let upper = utf8.distance(from: utf8.startIndex, to: searchRange.upperBound)

        guard let hit = lastUTF8Range(of: needle, in: lower..<upper) else { return nil }

        let start = utf8.index(utf8.startIndex, offsetBy: hit.lowerBound)
        let end = utf8.index(start, offsetBy: hit.count)
        return start..<end
    }
}
