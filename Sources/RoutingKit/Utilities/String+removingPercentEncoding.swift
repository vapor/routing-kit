#if canImport(FoundationEssentials)
    extension String {
        var removingPercentEncoding: String? {
            let source = self.utf8.span
            var failed: Bool = false

            // This will have to do until
            // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0485-outputspan.md#extensions
            // lands
            let result = [UInt8](capacity: source.count) { buffer in
                var i = 0
                while i < source.count {
                    let byte = source[i]
                    if byte == 0x25 {  // %
                        guard i + 2 < source.count,
                            let hi = Self.hexNibble(source[i + 1]),
                            let lo = Self.hexNibble(source[i + 2])
                        else {
                            failed = true
                            return
                        }
                        buffer.append((hi << 4) | lo)
                        i += 3
                    } else {
                        buffer.append(byte)
                        i += 1
                    }
                }
            }
            guard !failed else { return nil }
            return String(validating: result, as: UTF8.self)
        }

        private static func hexNibble(_ byte: UInt8) -> UInt8? {
            switch byte {
            case 0x30...0x39: byte - 0x30  // 0–9
            case 0x41...0x46: byte - 0x41 + 10  // A–F
            case 0x61...0x66: byte - 0x61 + 10  // a–f
            default: nil
            }
        }
    }
#endif
