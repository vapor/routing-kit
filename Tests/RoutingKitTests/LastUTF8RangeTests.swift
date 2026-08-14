import Testing

@testable import RoutingKit

@Suite
struct LastUTF8RangeTests {
    struct SearchCase: Sendable, CustomTestStringConvertible {
        let haystack: String
        let needle: String
        let range: Range<Int>?
        let expected: Range<Int>?

        var searchRange: Range<Int> { self.range ?? 0..<self.haystack.utf8.count }
        var testDescription: String { "\(self.haystack.debugDescription) / \(self.needle.debugDescription)" }
    }

    static let cases: [SearchCase] = [
        // Plain hit at the very end.
        .init(haystack: "users/42/posts.json", needle: ".json", range: nil, expected: 14..<19),
        // Backwards search returns the *last* occurrence.
        .init(haystack: "a/b.json/c.json", needle: ".json", range: nil, expected: 10..<15),
        // Overlapping repeats.
        .init(haystack: "aaaa", needle: "aa", range: nil, expected: 2..<4),
        // Whole string is the needle.
        .init(haystack: "abc", needle: "abc", range: nil, expected: 0..<3),
        // Hit sits exactly on the range's lower bound.
        .init(haystack: "zzabcz", needle: "abc", range: 2..<6, expected: 2..<5),
        // Hit sits exactly on the range's upper bound.
        .init(haystack: "zabcz", needle: "abc", range: 0..<4, expected: 1..<4),
        // No match at all.
        .init(haystack: "users/42/posts", needle: ".json", range: nil, expected: nil),
        // The only match is outside the search range.
        .init(haystack: "abc/def", needle: "abc", range: 3..<7, expected: nil),
        // The range cuts a match in half.
        .init(haystack: "x.jsonx", needle: ".json", range: 0..<5, expected: nil),
        // Empty needle.
        .init(haystack: "abc", needle: "", range: nil, expected: nil),
        // Needle longer than the search range.
        .init(haystack: "ab", needle: "abc", range: nil, expected: nil),
        // Search range runs past the end of the haystack.
        .init(haystack: "abc", needle: "abc", range: 0..<9, expected: nil),
        // Empty haystack.
        .init(haystack: "", needle: "abc", range: nil, expected: nil),
        // Multi-byte scalars: offsets are UTF-8 bytes, not characters.
        .init(haystack: "café/münchen.json", needle: "münchen", range: nil, expected: 6..<14),
        .init(haystack: "café/münchen.json", needle: ".json", range: nil, expected: 14..<19),
        .init(haystack: "🇮🇹/🇮🇹", needle: "🇮🇹", range: nil, expected: 9..<17),
    ]

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test("lastUTF8Range", arguments: cases)
    func lastUTF8Range(_ searchCase: SearchCase) {
        #expect(
            searchCase.haystack.lastUTF8Range(of: searchCase.needle[...], in: searchCase.searchRange)
                == searchCase.expected
        )
    }

    @Test("lastUTF8Range Dispatches to a Working Variant", arguments: cases)
    func dispatch(_ searchCase: SearchCase) {
        #expect(
            searchCase.haystack.lastUTF8Range(of: searchCase.needle[...], in: searchCase.searchRange)
                == searchCase.expected
        )
    }

    @Test("Backwards Range Maps Back to String Indices")
    func stringIndexMapping() throws {
        let path = "café/münchen.json/café/münchen.json"
        let found = try #require(path.range(of: "münchen"[...], backwardsIn: path.startIndex..<path.endIndex))
        #expect(path[found] == "münchen")
        #expect(path[path.startIndex..<found.lowerBound] == "café/münchen.json/café/")

        let firstHalf = try #require(path.firstRange(of: ".json"))
        let earlier = try #require(path.range(of: "münchen"[...], backwardsIn: path.startIndex..<firstHalf.lowerBound))
        #expect(path[path.startIndex..<earlier.lowerBound] == "café/")

        #expect(path.range(of: "nope"[...], backwardsIn: path.startIndex..<path.endIndex) == nil)
    }
}
