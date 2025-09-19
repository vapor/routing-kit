import RoutingKit
import Testing

@Suite
struct RouterTests {
    @Test func routing() async throws {
        var builder = TrieRouterBuilder(Int.self)
        builder.register(42, at: ["foo", "bar", "baz", ":user"])
        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["foo", "bar", "baz", "Tanner"], parameters: &params) == 42)
        #expect(params.get("user") == "Tanner")
    }

    @Test func caseSensitiveRouting() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: [.constant("path"), .constant("TO"), .constant("fOo")])
        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["PATH", "tO", "FOo"], parameters: &params) == nil)
        #expect(router.route(path: ["path", "TO", "fOo"], parameters: &params) == 42)
    }

    @Test func caseInsensitiveRouting() throws {
        var builder = TrieRouterBuilder<Int>(options: [.caseInsensitive])
        builder.register(42, at: [.constant("path"), .constant("TO"), .constant("fOo")])
        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["PATH", "tO", "FOo"], parameters: &params) == 42)
    }

    @Test func anyRouting() throws {
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

    @Test func wildcardRoutingHasNoPrecedence() throws {
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

    @Test func routerSuffixes() throws {
        var builder = TrieRouterBuilder<Int>(options: [.caseInsensitive])
        builder.register(1, at: [.constant("a")])
        builder.register(2, at: [.constant("aa")])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["a"], parameters: &params) == 1)
        #expect(router.route(path: ["aa"], parameters: &params) == 2)
    }

    @Test func docBlock() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: ["users", ":user"])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["users", "Tanner"], parameters: &params) == 42)
        #expect(params.get("user") == "Tanner")
    }

    @Test func docs() throws {
        var builder = TrieRouterBuilder(Double.self)
        builder.register(42, at: ["fun", "meaning_of_universe"])
        builder.register(1337, at: ["fun", "leet"])
        builder.register(3.14, at: ["math", "pi"])

        let router = builder.build()
        var params = Parameters()
        #expect(router.route(path: ["fun", "meaning_of_universe"], parameters: &params) == 42)
    }

    // https://github.com/vapor/routing/issues/64
    @Test func parameterPercentDecoding() throws {
        var builder = TrieRouterBuilder(String.self)
        builder.register("c", at: [.constant("a"), .parameter("b")])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["a", "te%20st"], parameters: &params) == "c")
        #expect(params.get("b") == "te st")
    }

    // https://github.com/vapor/routing-kit/issues/74
    @Test func catchallNested() throws {
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

    @Test func catchallPrecedence() throws {
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

    @Test func catchallValue() throws {
        var builder = TrieRouterBuilder<Int>()
        builder.register(42, at: ["users", ":user", "**"])
        builder.register(24, at: ["users", "**"])
        let router = builder.build()

        var params = Parameters()
        #expect(router.route(path: ["users"], parameters: &params) == nil)
        #expect(params.getCatchall().count == 0)
        #expect(router.route(path: ["users", "stevapple"], parameters: &params) == 24)
        #expect(params.getCatchall() == ["stevapple"])
        #expect(router.route(path: ["users", "stevapple", "posts", "2"], parameters: &params) == 42)
        #expect(params.getCatchall() == ["posts", "2"])
    }

    @Test func routerDescription() throws {
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

    @Test func pathComponentDescription() throws {
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

    @Test func testPathComponentInterpolation() throws {
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

    @Test func parameterNamesFetch() throws {
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
}
