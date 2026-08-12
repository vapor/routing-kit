#if canImport(FoundationEssentials)
    extension String {
        var removingPercentEncoding: String? {
            let source = self.utf8
            var result = [UInt8]()
            result.reserveCapacity(source.count)

            var i = source.startIndex
            while i < source.endIndex {
                let byte = source[i]
                if byte == 0x25 {  // %
                    guard
                        let hiIndex = source.index(i, offsetBy: 1, limitedBy: source.endIndex),
                        hiIndex < source.endIndex,
                        let loIndex = source.index(i, offsetBy: 2, limitedBy: source.endIndex),
                        loIndex < source.endIndex,
                        let hi = Self.hexNibble(source[hiIndex]),
                        let lo = Self.hexNibble(source[loIndex])
                    else { return nil }
                    result.append((hi << 4) | lo)
                    i = source.index(after: loIndex)
                } else {
                    result.append(byte)
                    source.formIndex(after: &i)
                }
            }
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
