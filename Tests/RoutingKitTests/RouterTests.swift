import RoutingKit
import Testing

@Suite
struct RouterTests {
    @Test("Simple Routing")
    func routing() async throws {
        var builder = TrieRouterBuilder(Int.self)
        builder.register(42, at: ["foo", "bar", "baz", ":user"])
        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: &params) == 42)
        #expect(params.get("user") == "Tanner")
    }

    @Test("Case-sensitive Routing")
    func caseSensitiveRouting() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: [.constant("path"), .constant("TO"), .constant("fOo")])
        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["PATH", "tO", "FOo"], parameters: &params) == nil)
        #expect(router.route(path: ["path", "TO", "fOo"], parameters: &params) == 42)
    }

    @Test("Case-insensitive Routing")
    func caseInsensitiveRouting() throws {
        var builder = TrieRouterBuilder<Int>(config: .caseInsensitive)
        builder.register(42, at: [.constant("path"), .constant("TO"), .constant("fOo")])
        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["PATH", "tO", "FOo"], parameters: &params) == 42)
    }

    @Test("Any Routing")
    func anyRouting() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(0, at: [.constant("a"), .anything])
        builder.register(1, at: [.constant("b"), .parameter("1"), .anything])
        builder.register(2, at: [.constant("c"), .parameter("1"), .parameter("2"), .anything])
        builder.register(3, at: [.constant("d"), .parameter("1"), .parameter("2")])
        builder.register(4, at: [.constant("e"), .parameter("1"), .catchall])
        builder.register(5, at: [.anything, .constant("e"), .parameter("1")])

        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["a", "b"], parameters: &params) == 0)
        #expect(router.route(path: ["a"], parameters: &params) == nil)
        #expect(router.route(path: ["a", "a"], parameters: &params) == 0)
        #expect(router.route(path: ["b", "a", "c"], parameters: &params) == 1)
        #expect(router.route(path: ["b"], parameters: &params) == nil)
        #expect(router.route(path: ["b", "a"], parameters: &params) == nil)
        #expect(router.route(path: ["b", "a", "c"], parameters: &params) == 1)
        #expect(router.route(path: ["c"], parameters: &params) == nil)
        #expect(router.route(path: ["c", "a"], parameters: &params) == nil)
        #expect(router.route(path: ["c", "b"], parameters: &params) == nil)
        #expect(router.route(path: ["d", "a", "b"], parameters: &params) == 3)
        #expect(router.route(path: ["d", "a", "b", "c"], parameters: &params) == nil)
        #expect(router.route(path: ["d", "a"], parameters: &params) == nil)
        #expect(router.route(path: ["e", "1", "b", "a"], parameters: &params) == 4)
        #expect(router.route(path: ["f", "e", "1"], parameters: &params) == 5)
        #expect(router.route(path: ["g", "e", "1"], parameters: &params) == 5)
        #expect(router.route(path: ["g", "e", "1"], parameters: &params) == 5)
    }

    @Test("Wildcard Routing has no Precedence")
    func wildcardRoutingHasNoPrecedence() throws {
        var builder1 = TrieRouterBuilder<Int>()
        builder1.register(0, at: [.constant("a"), .parameter("1"), .constant("a")])
        builder1.register(1, at: [.constant("a"), .anything, .constant("b")])
        let router1 = builder1.build()

        var builder2 = TrieRouterBuilder<Int>()
        builder2.register(0, at: [.constant("a"), .anything, .constant("a")])
        builder2.register(1, at: [.constant("a"), .anything, .constant("b")])
        let router2 = builder2.build()

        var params1 = Parameters()
        var params2 = Parameters()
        let path = ["a", "1", "b"]

        #expect(router1.route(path: path, parameters: &params1) == 1)
        #expect(router2.route(path: path, parameters: &params2) == 1)
    }

    @Test("Router Suffixes")
    func routerSuffixes() throws {
        var builder = TrieRouterBuilder<Int>(config: .caseInsensitive)
        builder.register(1, at: [.constant("a")])
        builder.register(2, at: [.constant("aa")])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["a"], parameters: &params) == 1)
        #expect(router.route(path: ["aa"], parameters: &params) == 2)
    }

    @Test("Doc Block")
    func docBlock() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: ["users", ":user"])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["users", "Tanner"], parameters: &params) == 42)
        #expect(params.get("user") == "Tanner")
    }

    @Test("Docs")
    func docs() throws {
        var builder = TrieRouterBuilder(Double.self)
        builder.register(42, at: ["fun", "meaning_of_universe"])
        builder.register(1337, at: ["fun", "leet"])
        builder.register(3.14, at: ["math", "pi"])

        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["fun", "meaning_of_universe"], parameters: &params) == 42)
    }

    @Test("Parameter Percent-encoding", .bug("https://github.com/vapor/routing/issues/64"))
    func parameterPercentDecoding() throws {
        var builder = TrieRouterBuilder(String.self)
        builder.register("c", at: [.constant("a"), .parameter("b")])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["a", "te%20st"], parameters: &params) == "c")
        #expect(params.get("b") == "te st")
    }

    @Test("Nested Catch-all", .bug("https://github.com/vapor/routing-kit/issues/74"))
    func catchallNested() throws {
        var builder = TrieRouterBuilder(String.self)
        builder.register("/**", at: [.catchall])
        builder.register("/a/**", at: ["a", .catchall])
        builder.register("/a/b/**", at: ["a", "b", .catchall])
        builder.register("/a/b", at: ["a", "b"])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["a"], parameters: &params) == "/**")
        #expect(router.route(path: ["a", "b"], parameters: &params) == "/a/b")
        #expect(router.route(path: ["a", "b", "c"], parameters: &params) == "/a/b/**")
        #expect(router.route(path: ["a", "c"], parameters: &params) == "/a/**")
        #expect(router.route(path: ["b"], parameters: &params) == "/**")
        #expect(router.route(path: ["b", "c", "d", "e"], parameters: &params) == "/**")
    }

    @Test("Catch-all Precedence")
    func catchallPrecedence() throws {
        var builder = TrieRouterBuilder(String.self)
        builder.register("a", at: ["v1", "test"])
        builder.register("b", at: ["v1", .catchall])
        builder.register("c", at: ["v1", .anything])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["v1", "test"], parameters: &params) == "a")
        #expect(router.route(path: ["v1", "test", "foo"], parameters: &params) == "b")
        #expect(router.route(path: ["v1", "foo"], parameters: &params) == "c")
    }

    @Test("Catch-all Value")
    func catchallValue() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: ["users", ":user", "**"])
        builder.register(24, at: ["users", "**"])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["users"], parameters: &params) == nil)
        #expect(params.getCatchall().isEmpty)
        #expect(router.route(path: ["users", "stevapple"], parameters: &params) == 24)
        #expect(params.getCatchall() == ["stevapple"])
        #expect(router.route(path: ["users", "stevapple", "posts", "2"], parameters: &params) == 42)
        #expect(params.getCatchall() == ["posts", "2"])
    }

    @Test("Router Description")
    func routerDescription() throws {
        // Use simple routing to eliminate the impact of registration order
        let constA: PathComponent = "a"
        let constOne: PathComponent = "1"
        let paramOne: PathComponent = .parameter("1")
        let anything: PathComponent = .anything
        let catchall: PathComponent = .catchall
        var builder = TrieRouterBuilder<Int>()
        builder.register(0, at: [constA, anything])
        builder.register(1, at: [constA, constOne, catchall])
        builder.register(2, at: [constA, constOne, anything])
        builder.register(3, at: [anything, constA, paramOne])
        builder.register(4, at: [catchall])
        // Manually build description
        let desc = """
            → \(constA)
              → \(constOne)
                → \(anything)
                → \(catchall)
              → \(anything)
            → \(anything)
              → \(constA)
                → \(paramOne)
            → \(catchall)
            """
        let router = builder.build()
        #expect(router.description == desc)
    }

    @Test("Path Component Description")
    func pathComponentDescription() throws {
        let paths = [
            "aaaaa/bbbb/ccc/dd",
            "123/:45/6/789",
            "123/**",
            "*/*/*/**",
            ":12/12/*",
        ]
        for path in paths {
            #expect(path.pathComponents.string == path)
            #expect(("/" + path).pathComponents.string == path)
        }
    }

    @Test("Path Component Interpolation")
    func testPathComponentInterpolation() throws {
        do {
            let pathComponentLiteral: PathComponent = "path"
            switch pathComponentLiteral {
            case .constant(let value):
                #expect(value == "path")
            default:
                Issue.record("pathComponentLiteral \(pathComponentLiteral) is not .constant(\"path\")")
            }
        }
        do {
            let pathComponentLiteral: PathComponent = ":path"
            switch pathComponentLiteral {
            case .parameter(let value):
                #expect(value == "path")
            default:
                Issue.record("pathComponentLiteral \(pathComponentLiteral) is not .parameter(\"path\")")
            }
        }
        do {
            let pathComponentLiteral: PathComponent = "*"
            switch pathComponentLiteral {
            case .anything:
                break
            default:
                Issue.record("pathComponentLiteral \(pathComponentLiteral) is not .anything")
            }
        }
        do {
            let pathComponentLiteral: PathComponent = "**"
            switch pathComponentLiteral {
            case .catchall:
                break
            default:
                Issue.record("pathComponentLiteral \(pathComponentLiteral) is not .catchall")
            }
        }
        do {
            let constant = "foo"
            let pathComponentInterpolation: PathComponent = "\(constant)"
            switch pathComponentInterpolation {
            case .constant(let value):
                #expect(value == "foo")
            default:
                Issue.record("pathComponentInterpolation \(pathComponentInterpolation) is not .constant(\"foo\")")
            }
        }
        do {
            let parameter = "foo"
            let pathComponentInterpolation: PathComponent = ":\(parameter)"
            switch pathComponentInterpolation {
            case .parameter(let value):
                #expect(value == "foo")
            default:
                Issue.record("pathComponentInterpolation \(pathComponentInterpolation) is not .parameter(\"foo\")")
            }
        }
        do {
            let anything = "*"
            let pathComponentInterpolation: PathComponent = "\(anything)"
            switch pathComponentInterpolation {
            case .anything:
                break
            default:
                Issue.record("pathComponentInterpolation \(pathComponentInterpolation) is not .anything")
            }
        }
        do {
            let catchall = "**"
            let pathComponentInterpolation: PathComponent = "\(catchall)"
            switch pathComponentInterpolation {
            case .catchall:
                break
            default:
                Issue.record("pathComponentInterpolation \(pathComponentInterpolation) is not .catchall")
            }
        }
    }

    @Test("Parameter Name Fetch")
    func parameterNamesFetch() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: ["foo", ":bar", ":baz", ":bam"])
        builder.register(24, at: ["bar", ":bar", "**"])
        let router = builder.build()

        var params1 = Parameters()
        #expect(router.route(path: ["foo"], parameters: &params1) == nil)
        #expect(params1.getCatchall().isEmpty)

        var params2 = Parameters()
        #expect(router.route(path: ["foo", "a", "b", "c"], parameters: &params2) == 42)
        #expect(Set(params2.allNames) == ["bar", "baz", "bam"])  // Set will compare equal regardless of ordering
        #expect(params2.getCatchall().isEmpty)

        var params3 = Parameters()
        #expect(router.route(path: ["bar", "baz", "bam"], parameters: &params3) == 24)
        #expect(Set(params3.allNames) == ["bar"])
        #expect(params3.getCatchall() == ["bam"])
    }

    @Test("Partial Happy Path")
    func partialHappyPath() throws {
        var routerBuilder = TrieRouterBuilder<Int>()
        routerBuilder.register(42, at: ["test", ":{my-file}.json"])
        routerBuilder.register(41, at: ["test", ":{my}-test-{file}.{extension}"])

        let router = routerBuilder.build()

        var params = Parameters()
        #expect(router.route(path: ["test", "report.json"], parameters: &params) == 42)
        #expect(params.get("my-file") == "report")

        #expect(router.route(path: ["test", ".json.json"], parameters: &params) == 42)
        #expect(params.get("my-file") == ".json")

        params = Parameters()
        #expect(router.route(path: ["test", "foo-test-bar.txt"], parameters: &params) == 41)
        #expect(params.get("my") == "foo")
        #expect(params.get("file") == "bar")
        #expect(params.get("extension") == "txt")
    }

    @Test("Partial Param at Start or End")
    func partialParamAtStartAndEnd() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(10, at: ["p", ":{a}-suffix"])
        builder.register(11, at: ["p", ":prefix-{b}"])

        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["p", "foo-suffix"], parameters: &params) == 10)
        #expect(params.get("a") == "foo")

        params = Parameters()
        #expect(router.route(path: ["p", "prefix-bar"], parameters: &params) == 11)
        #expect(params.get("b") == "bar")
    }

    #if swift(>=6.2) && !os(Android)
        @Test("Partial Unclosed Parameter Fails")
        func testPartialUnclosedParameterFails() async throws {
            await #expect(processExitsWith: .failure) {
                var builder = TrieRouterBuilder<Int>()
                builder.register(20, at: ["p", ":{open"])
            }
        }
    #endif

    @Test("Partial Greedy Anchors")
    func testPartialGreedyAnchors() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(1, at: ["x", ":{a}.json.json"])
        builder.register(2, at: ["x", ":{a}.json"])
        let router = builder.build()

        var p = Parameters()
        #expect(router.route(path: ["x", ".json.json"], parameters: &p) == 1)
        #expect(p.get("a") == "")
        p = Parameters()
        #expect(router.route(path: ["x", "file.json"], parameters: &p) == 2)
        #expect(p.get("a") == "file")
    }

    @Test("Partial Ordering Specificity")
    func testPartialOrderingSpecificity() throws {
        var b = TrieRouterBuilder<Int>()
        b.register(1, at: ["y", ":{a}.{ext}"])
        b.register(2, at: ["y", ":prefix-{b}.txt"])
        let r = b.build()

        var p = Parameters()
        #expect(r.route(path: ["y", "prefix-foo.txt"], parameters: &p) == 2)
        #expect(p.get("b") == "foo")
        p = Parameters()
        #expect(r.route(path: ["y", "file.md"], parameters: &p) == 1)
    }

    @Test("Catchall catches empty path", .bug("https://github.com/vapor/routing-kit/issues/147"))
    func emptyCatchall() throws {
        var b = TrieRouterBuilder<Int>()
        b.register(1, at: [.catchall])
        let r = b.build()

        var p = Parameters()
        #expect(r.route(path: [], parameters: &p) == 1)
    }

    @Test("Backtracking", .bug("https://github.com/vapor/routing-kit/issues/145"))
    func backtracking() throws {
        var b = TrieRouterBuilder<Int>()
        b.register(1, at: [":provider"])
        b.register(2, at: ["google", "callback"])
        b.register(3, at: [":provider", "test"])
        let r = b.build()

        var p = Parameters()
        #expect(r.route(path: ["google"], parameters: &p) == 1)
        #expect(r.route(path: ["google", "test"], parameters: &p) == 3)
    }

    @Test("Wildcard vs Constant Backtrack")
    func wildcardVsConstantBacktrack() throws {
        var b = TrieRouterBuilder<Int>()
        b.register(1, at: [":x", "b"])
        b.register(2, at: ["a", "c"])
        let r = b.build()

        var p = Parameters()
        #expect(r.route(path: ["a", "b"], parameters: &p) == 1)
    }

    @Test("Multiple wildcard alternatives")
    func multipleWildcards() throws {
        var b = TrieRouterBuilder<Int>()
        b.register(1, at: [":a", ":b", "tail"])
        b.register(2, at: [":a"])
        let r = b.build()

        var p = Parameters()
        #expect(r.route(path: ["one", "two", "tail"], parameters: &p) == 1)
        #expect(r.route(path: ["one"], parameters: &p) == 2)
    }
}
