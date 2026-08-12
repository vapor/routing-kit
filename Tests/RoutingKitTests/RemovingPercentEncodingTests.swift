#if canImport(FoundationEssentials)
    import Testing

    @testable import RoutingKit

    @Suite
    struct RemovingPercentEncodingTests {
        struct DecodeCase: Sendable, CustomTestStringConvertible {
            let encoded: String
            let expected: String?

            var testDescription: String { self.encoded.debugDescription }
        }

        @Test(
            "Decodes Valid Input",
            arguments: [
                DecodeCase(encoded: "", expected: ""),
                DecodeCase(encoded: "plain-segment", expected: "plain-segment"),
                DecodeCase(encoded: "hello%20world", expected: "hello world"),
                DecodeCase(encoded: "a%2Fb", expected: "a/b"),
                DecodeCase(encoded: "a%20b%2Fc", expected: "a b/c"),
                DecodeCase(encoded: "%41%42", expected: "AB"),
                DecodeCase(encoded: "%20", expected: " "),
                DecodeCase(encoded: "%2F%2F", expected: "//"),
                DecodeCase(encoded: "%2f", expected: "/"),
                DecodeCase(encoded: "%e2%9c%93", expected: "✓"),
                DecodeCase(encoded: "100%25", expected: "100%"),
                DecodeCase(encoded: "%E2%9C%93", expected: "✓"),
                DecodeCase(encoded: "caf%C3%A9", expected: "café"),
                DecodeCase(encoded: "%F0%9F%87%AE%F0%9F%87%B9", expected: "🇮🇹"),
                DecodeCase(encoded: "café%20x", expected: "café x"),
                DecodeCase(encoded: "+", expected: "+"),
                DecodeCase(encoded: "a+b", expected: "a+b"),
                DecodeCase(encoded: "%00", expected: "\0"),
            ]
        )
        func decodesValidInput(_ decodeCase: DecodeCase) {
            #expect(decodeCase.encoded.removingPercentEncoding == decodeCase.expected)
        }

        @Test(
            "Rejects Malformed Input",
            arguments: [
                "%", "%2", "abc%", "%20%",
                "%zz", "%2G", "%%20",
                "%FF", "%C3",
            ]
        )
        func rejectsMalformedInput(_ encoded: String) {
            #expect(encoded.removingPercentEncoding == nil)
        }

        @Test("Parameters Keep Undecodable Values Verbatim")
        func parametersFallBackToRawValue() {
            var parameters = Parameters()
            parameters.set("valid", to: "hello%20world")
            parameters.set("malformed", to: "100%")
            parameters.setCatchall(matched: ["a%2Fb", "%zz"])

            #expect(parameters.get("valid") == "hello world")
            #expect(parameters.get("malformed") == "100%")
            #expect(parameters.getCatchall() == ["a/b", "%zz"])
        }
    }
#endif
