import XCTest
import Branches

class BranchTests: XCTestCase {
    static let allTests = [
        ("testSimple", testSimple),
        ("testWildcard", testWildcard),
        ("testWildcardTrailing", testWildcardTrailing),
        ("testLeadingPath", testLeadingPath),
        ("testEmpty", testEmpty)
    ]

    func testSimple() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend(["a", "b", "c"], output: "abc")
        let result = base.fetch(["a", "b", "c"])
        XCTAssert(result?.output == "abc")
    }

    func testWildcard() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend(["a", "b", "c", "*"], output: "abc")
        let result = base.fetch(["a", "b", "c"])
        XCTAssert(result?.output == "abc")
    }

    func testWildcardTrailing() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend(["a", "b", "c", "*"], output: "abc")
        guard let result = base.fetch(["a", "b", "c", "d", "e", "f"]) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        XCTAssert(result.output == "abc")
    }

    func testLeadingPath() {
        let base = Branch<String>(name: "[base]", output: nil)
        let subBranch = base.extend([":a", ":b", ":c", "*"], output: "abc")
        XCTAssert(subBranch.path == [":a", ":b", ":c", "*"])
    }

    func testEmpty() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend(["a", "b", "c"], output: "abc")
        let result = base.fetch(["z"])
        XCTAssert(result == nil)

    }
}
