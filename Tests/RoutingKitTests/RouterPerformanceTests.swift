import RoutingKit
import XCTest

public final class RouterPerformanceTests: XCTestCase {
    public func testCaseSensitivePerformance() throws {
        guard performance(expected: 0.024) else { return }
        let router = TrieRouter(String.self)
        for letter in ["a", "b", "c", "d", "e" , "f", "g"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a", "42"], parameters: &params)
            }
        }
    }
    
    public func testCaseInsensitivePerformance() throws {
        guard performance(expected: 0.032) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a", "b", "c", "d", "e" , "f", "g"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a", "42"], parameters: &params)
            }
        }
    }
    
    public func testCaseInsensitiveRoutingMatchFirstPerformance() throws {
        guard performance(expected: 0.045) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae" , "aaaaaaaf", "aaaaaaag"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["aaaaaaaa", "42"], parameters: &params)
            }
        }
    }
    
    public func testCaseInsensitiveRoutingMatchLastPerformance() throws {
        guard performance(expected: 0.046) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae" , "aaaaaaaf", "aaaaaaag"] {
            router.register(route: Route(path: [
                .constant(letter),
                .parameter("\(letter)_id")
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["aaaaaaag", "42"], parameters: &params)
            }
        }
    }
    
    public func testMinimalRouterCaseSensitivePerformance() throws {
        guard performance(expected: 0.021) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a"] {
            router.register(route: Route(path: [
                .constant(letter)
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a"], parameters: &params)
            }
        }
    }
    
    public func testMinimalRouterCaseInsensitivePerformance() throws {
        guard performance(expected: 0.016) else { return }
        let router = TrieRouter.init(String.self)
        for letter in ["a"] {
            router.register(route: Route(path: [
                .constant(letter)
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["a"], parameters: &params)
            }
        }
    }
    
    
    public func testMinimalEarlyFailPerformance() throws {
        guard performance(expected: 0.013) else { return }
        let router = TrieRouter.init(String.self)
        for letter in ["aaaaaaaaaaaaaa"] {
            router.register(route: Route(path: [
                .constant(letter)
            ], output: letter))
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<100_000 {
                _ = router.route(path: ["baaaaaaaaaaaaa"], parameters: &params)
            }
        }
    }

    public static let allTests = [
        ("testCaseSensitivePerformance", testCaseSensitivePerformance),
        ("testCaseInsensitivePerformance", testCaseInsensitivePerformance),
        ("testCaseInsensitiveRoutingMatchFirstPerformance", testCaseInsensitiveRoutingMatchFirstPerformance),
        ("testCaseInsensitiveRoutingMatchLastPerformance", testCaseInsensitiveRoutingMatchLastPerformance),
        ("testMinimalRouterCaseInsensitivePerformance", testMinimalRouterCaseInsensitivePerformance),
        ("testMinimalRouterCaseSensitivePerformance", testMinimalRouterCaseSensitivePerformance),
        ("testMinimalEarlyFailPerformance", testMinimalEarlyFailPerformance),
    ]
}

func performance(expected seconds: Double, name: String = #function) -> Bool {
    guard !_isDebugAssertConfiguration() else {
        print("[PERFORMANCE] Skipping \(name) in debug build mode")
        return false
    }
    print("[PERFORMANCE] \(name) expected: \(seconds) seconds")
    return true
}
