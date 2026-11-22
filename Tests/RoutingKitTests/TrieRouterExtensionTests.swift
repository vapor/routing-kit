import XCTest

@testable import RoutingKit

/// The fork's own additions to `TrieRouter`: neighbours, traversal, map, zip, merge, slices, supersets and the
/// precedence of parameters; XCTest, like the rest of the fork's suite.
final class TrieRouterExtensionTests: XCTestCase {
    func testConstantNeighboursFetch() throws {
        let router = TrieRouter<Int>()
        router.register(42, at: ["foo", "bar", "yoo"])
        router.register(24, at: ["bar", "bar"])
        router.register(12, at: ["bar", "man"])
        router.register(6, at: ["bar", "man", ":yoo"])
        router.register(12, at: ["bar", "man", "joe"])

        let neighbours = router.neighbours(path: ["bar"])

        XCTAssertNotNil(neighbours)
        XCTAssertNotNil(
            neighbours?.firstIndex(where: { node in
                return node.getOutput() == 24
            }))
        XCTAssertNotNil(
            neighbours?.firstIndex(where: { node in
                return node.getOutput() == 12
            }))
        XCTAssertNil(
            neighbours?.firstIndex(where: { node in
                return node.getOutput() == 6
            }))
        XCTAssertEqual(neighbours?.count, 2)

        let emptyRouter = TrieRouter<Int>()
        let emptyNeighbours = emptyRouter.neighbours(path: [])

        XCTAssertEqual(emptyNeighbours?.count, 0)

        let level1LeavesRouter = TrieRouter<Int>()
        level1LeavesRouter.register(12, at: ["foo"])
        level1LeavesRouter.register(6, at: ["bar"])

        let rootNeighbours = level1LeavesRouter.neighbours(path: [])

        XCTAssertNotNil(rootNeighbours)
        XCTAssertEqual(rootNeighbours?.count, 2)
        XCTAssertTrue(
            rootNeighbours?.firstIndex(where: { node in
                return node.getOutput() == 12
            }) != nil)
        XCTAssertTrue(
            rootNeighbours?.firstIndex(where: { node in
                return node.getOutput() == 6
            }) != nil)
        XCTAssertFalse(
            rootNeighbours?.firstIndex(where: { node in
                return node.getOutput() == 3
            }) != nil)

    }

    func testMap() throws {
        let router = TrieRouter<Int>()
        router.register(0, at: [">", "Police", "zoom"])
        router.register(1, at: [">", "Police"])
        router.register(2, at: [">", "Depot"])
        router.register(3, at: [">", "Shutters"])
        router.register(4, at: [">", "Cakes"])
        router.register(5, at: [">", "SpacelandSign", "zoom"])
        router.register(6, at: [">", "SpacelandSign"])

        router.map { absolutePath, output in
            return absolutePath
        }.forEach { path in
            print(path)
        }
    }

    func testForEachBFS() throws {
        let router = TrieRouter<(String, Int)>()
        router.register(("PoliceZoom", 0), at: [">", "Police", "zoom"])
        router.register(("Police", 0), at: [">", "Police"])
        router.register(("Depot", 1), at: [">", "Depot"])
        router.register(("Shutters", 2), at: [">", "Shutters"])
        router.register(("Cakes", 3), at: [">", "Cakes"])
        router.register(("SpacelandSignZoom", 0), at: [">", "SpacelandSign", "zoom"])
        router.register(("SpacelandSign", 4), at: [">", "SpacelandSign"])
        router.register(("SpacelandSignZoomRaveZoom", 0), at: [">", "SpacelandSign", "zoom", "rave", "zoom"])

        print(
            router.toDOT { absolutePath, output in
                if let output = output {
                    return output.0
                } else {
                    return absolutePath.last!
                }
            })

        router.forEachBFS { neighbours in
            return neighbours.sorted { lhs, rhs in
                guard let lhsOut = lhs.getOutput(), let rhsOut = rhs.getOutput() else { return false }
                return lhsOut.1 < rhsOut.1
            }
        } shouldVisitNeighbours: { nodeInfo in
            return nodeInfo.getAbsolutePath().count <= 1
        } _: { path, output in
            print(path, output)
        }
    }

    /// Tests successful, now `<`, `<=`, `sharesRoutes` became `internal` and therefore the ability to run this test is missing.
    /*
    func testArrayLessThanOperator() throws {
        XCTAssertEqual([">", "police", "zoom"] < [">", "police"], false)
        XCTAssertEqual([">", "police", "zoom"] < [">", "police", "zoom"], false)
        XCTAssertEqual([">", "police", "zoom"] <= [">", "police", "zoom"], true)
        XCTAssertEqual([">", "police"] < [">", "police", "zoom"], true)
        XCTAssertEqual([] < [], false)
        XCTAssertEqual([] <= [], true)
    }

    func testSharesRoutes() throws {
        let lhs = TrieRouter<(String, Int)>()
        let rhs = TrieRouter<(String, Double)>()

        XCTAssertEqual(lhs.sharesRoutes(with: rhs), true)
        XCTAssertEqual(rhs.sharesRoutes(with: lhs), true)

        lhs.register(("PoliceZoom", 0), at: [">", "Police", "zoom"])
        lhs.register(("Police", 0), at: [">", "Police"])
        lhs.register(("Depot", 1), at: [">", "Depot"])
        lhs.register(("Shutters", 2), at: [">", "Shutters"])
        lhs.register(("Cakes", 3), at: [">", "Cakes"])
        lhs.register(("SpacelandSignZoom", 0), at: [">", "SpacelandSign", "zoom"])
        lhs.register(("SpacelandSign", 4), at: [">", "SpacelandSign"])

        rhs.register(("SpacelandSignZoom", 0), at: [">", "SpacelandSign", "zoom"])
        rhs.register(("SpacelandSign", 4), at: [">", "SpacelandSign"])
        rhs.register(("Police", 0), at: [">", "Police"])
        rhs.register(("PoliceZoom", 0), at: [">", "Police", "zoom"])
        rhs.register(("Shutters", 2), at: [">", "Shutters"])
        rhs.register(("Depot", 1), at: [">", "Depot"])
        rhs.register(("Cakes", 3), at: [">", "Cakes"])

        XCTAssertEqual(lhs.sharesRoutes(with: rhs), true)
        XCTAssertEqual(rhs.sharesRoutes(with: lhs), true)

        lhs.register(("SpacelandSignZoomRaveZoom", 0), at: [">", "SpacelandSign", "zoom", "rave", "zoom"])

        XCTAssertEqual(lhs.sharesRoutes(with: rhs), false)
        XCTAssertEqual(rhs.sharesRoutes(with: lhs), false)
    }
     */

    func testZipRouters() throws {
        let lhs = TrieRouter<(String, Int)>()
        let rhs = TrieRouter<(String, Double)>()

        lhs.register(("PoliceZoom", 0), at: [">", "Police", "zoom"])
        lhs.register(("Police", 0), at: [">", "Police"])
        lhs.register(("Depot", 1), at: [">", "Depot"])
        lhs.register(("Shutters", 2), at: [">", "Shutters"])
        lhs.register(("Cakes", 3), at: [">", "Cakes"])
        lhs.register(("SpacelandSignZoom", 0), at: [">", "SpacelandSign", "zoom"])
        lhs.register(("SpacelandSign", 4), at: [">", "SpacelandSign"])

        rhs.register(("SpacelandSignZoom", 0), at: [">", "SpacelandSign", "zoom"])
        rhs.register(("SpacelandSign", 4), at: [">", "SpacelandSign"])
        rhs.register(("Police", 0), at: [">", "Police"])
        rhs.register(("PoliceZoom", 0), at: [">", "Police", "zoom"])
        rhs.register(("Shutters", 2), at: [">", "Shutters"])
        rhs.register(("Depot", 1), at: [">", "Depot"])
        rhs.register(("Cakes", 3), at: [">", "Cakes"])

        let zip = lhs.zip(to: rhs) { absolutePath, lhsOutput, rhsOutput in
            return (lhsOutput, rhsOutput)
        }

        XCTAssertNotNil(zip)

        zip?.forEach { absolutePath, output in
            XCTAssertEqual(output.0.0, output.1.0)
        }

        lhs.register(("SpacelandSignZoomRaveZoom", 0), at: [">", "SpacelandSign", "zoom", "rave", "zoom"])

        let second = lhs.zip(to: rhs) { absolutePath, lhsOutput, rhsOutput in
            return (lhsOutput, rhsOutput)
        }

        XCTAssertNil(second)
    }

    func testHasSlice() throws {
        let lhs = TrieRouter<(String, Int)>()

        lhs.register(("PoliceZoom", 0), at: [">", "Police", "zoom"])
        lhs.register(("Police", 0), at: [">", "Police"])
        lhs.register(("Depot", 1), at: [">", "Depot"])
        lhs.register(("Shutters", 2), at: [">", "Shutters"])
        lhs.register(("Cakes", 3), at: [">", "Cakes"])
        lhs.register(("SpacelandSignZoom", 0), at: [">", "SpacelandSign", "zoom"])
        lhs.register(("SpacelandSign", 4), at: [">", "SpacelandSign"])

        XCTAssertTrue(lhs.hasSlice(named: ">"))
        XCTAssertTrue(lhs.hasSlice(named: "Depot"))
        XCTAssertTrue(lhs.hasSlice(named: "zoom"))
        XCTAssertFalse(lhs.hasSlice(named: "zoom", rootPath: [">", "Cakes"]))
    }

    func testIsSuperSet() throws {
        let lhs = TrieRouter<Int>()
        lhs.register(0, at: [">", "Police", "zoom"])
        lhs.register(0, at: [">", "Police"])
        lhs.register(1, at: [">", "Depot"])
        lhs.register(2, at: [">", "Shutters"])
        lhs.register(3, at: [">", "Cakes"])
        lhs.register(0, at: [">", "SpacelandSign", "zoom"])
        lhs.register(4, at: [">", "SpacelandSign"])

        XCTAssertTrue(lhs.isSuperSet(of: lhs))

        let rhs = TrieRouter<Double>()

        XCTAssertTrue(lhs.isSuperSet(of: rhs))
        XCTAssertFalse(rhs.isSuperSet(of: lhs))

        rhs.register(1, at: [">", "Depot"])
        rhs.register(2, at: [">", "Shutters"])
        rhs.register(3, at: [">", "Cakes"])
        rhs.register(0, at: [">", "SpacelandSign", "zoom"])
        rhs.register(4, at: [">", "SpacelandSign"])

        XCTAssertTrue(lhs.isSuperSet(of: rhs))
        XCTAssertFalse(rhs.isSuperSet(of: lhs))

        rhs.register(4, at: [">", "SpacelandSign", "Rave"])

        rhs.forEachBFS(rootPath: [">", "Maronna"]) { absoltePath, output in
            print(absoltePath)
        }

        XCTAssertFalse(lhs.isSuperSet(of: rhs))
        XCTAssertFalse(rhs.isSuperSet(of: lhs))
    }

    func testNeighbours() throws {
        let router = TrieRouter<Int>()
        router.register(0, at: [">", "the final reich"])
        router.register(1, at: [">", "the darkest shore"])
        router.register(2, at: [">", "the shadowed throne"])
        router.register(3, at: [">", "the tortured path"])
        router.register(4, at: [">", "the frozen dawn"])
        router.register(0, at: [">", "the tortured path", "into the storm"])
        router.register(1, at: [">", "the tortured path", "across the depths"])
        router.register(2, at: [">", "the tortured path", "beneath the ice"])

        XCTAssertEqual(
            router.reduceNeighbours(parentPath: [">", "the darkest shore"], 0) { partialResult, _, _ in
                return partialResult + 1
            }, 0)

        XCTAssertEqual(
            router.reduceNeighbours(parentPath: [">", "the tortured path"], 0) { partialResult, _, _ in
                return partialResult + 1
            }, 3)
    }

    func testParametersPrecedence() throws {
        let router = TrieRouter<Int>()
        router.options.insert(.caseInsensitive)

        router.register(
            1,
            at: [.constant("home"), .parameter("game"), .parameter("map"), .parameter("tool")]
        )

        router.register(
            0,
            at: [.constant("home"), .parameter("game"), .constant("the tortured path"), .parameter("map"), .parameter("tool")]
        )

        var params: Parameters = .init()
        let result = router.route(path: ["home", "wwii", "the tortured path", "beneath the ice", "fish"], parameters: &params)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, 0)

        let bo6output = router.route(path: ["home", "iw", "spaceland", "seti"], parameters: &params)
        XCTAssertNotNil(bo6output)
        XCTAssertEqual(bo6output, 1)
    }
}
