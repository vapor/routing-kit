import XCTest
import Branches

class BranchTests: XCTestCase {
    static let allTests = [
        ("testSimple", testSimple),
        ("testWildcard", testWildcard),
        ("testWildcardTrailing", testWildcardTrailing),
        ("testParams", testParams),
        ("testOutOfBoundsParams", testOutOfBoundsParams),
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

    func testParams() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend([":a", ":b", ":c", "*"], output: "abc")
        let path = ["zero", "one", "two", "d", "e", "f"]
        guard let result = base.fetch(path) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        let params = result.slugs(for: path)
        XCTAssert(params["a"] == "zero")
        XCTAssert(params["b"] == "one")
        XCTAssert(params["c"] == "two")
        XCTAssert(result.output == "abc")
    }

    func testOutOfBoundsParams() {
        let base = Branch<String>(name: "[base]", output: nil)
        base.extend([":a", ":b", ":c", "*"], output: "abc")
        let path = ["zero", "one", "two", "d", "e", "f"]
        guard let result = base.fetch(path) else {
            XCTFail("invalid wildcard fetch")
            return
        }

        let params = result.slugs(for: ["zero", "one"])
        XCTAssert(params["a"] == "zero")
        XCTAssert(params["b"] == "one")
        XCTAssert(params["c"] == nil)
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
