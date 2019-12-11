import RoutingKit
import XCTest

final class RouterPerformanceTests: XCTestCase {
    func testCaseSensitivePerformance() throws {
        guard performance(expected: 0.039) else { return }
        let router = TrieRouter(String.self)
        for letter in ["a", "b", "c", "d", "e" , "f", "g"] {
            router.register(letter, at:[
                .constant(letter),
                .parameter("\(letter)_id")
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["a", "42"], parameters: &params)
            }
        }
    }
    
    func testCaseInsensitivePerformance() throws {
        guard performance(expected: 0.050) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a", "b", "c", "d", "e" , "f", "g"] {
            router.register(letter, at: [
                .constant(letter),
                .parameter("\(letter)_id")
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["a", "42"], parameters: &params)
            }
        }
    }
    
    func testCaseInsensitiveRoutingMatchFirstPerformance() throws {
        guard performance(expected: 0.062) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae" , "aaaaaaaf", "aaaaaaag"] {
            router.register(letter, at: [
                .constant(letter),
                .parameter("\(letter)_id")
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["aaaaaaaa", "42"], parameters: &params)
            }
        }
    }
    
    func testCaseInsensitiveRoutingMatchLastPerformance() throws {
        guard performance(expected: 0.063) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae" , "aaaaaaaf", "aaaaaaag"] {
            router.register(letter, at: [
                .constant(letter),
                .parameter("\(letter)_id")
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["aaaaaaag", "42"], parameters: &params)
            }
        }
    }
    
    func testMinimalRouterCaseSensitivePerformance() throws {
        guard performance(expected: 0.022) else { return }
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a"] {
            router.register(letter, at: [
                .constant(letter)
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["a"], parameters: &params)
            }
        }
    }
    
    func testMinimalRouterCaseInsensitivePerformance() throws {
        guard performance(expected: 0.017) else { return }
        let router = TrieRouter.init(String.self)
        for letter in ["a"] {
            router.register(letter, at: [
                .constant(letter)
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["a"], parameters: &params)
            }
        }
    }
    
    
    func testMinimalEarlyFailPerformance() throws {
        guard performance(expected: 0.016) else { return }
        let router = TrieRouter.init(String.self)
        for letter in ["aaaaaaaaaaaaaa"] {
            router.register(letter, at: [
                .constant(letter)
            ])
        }
        
        measure {
            var params = Parameters()
            for _ in 0..<1_000_000 {
                _ = router.route(path: ["baaaaaaaaaaaaa"], parameters: &params)
            }
        }
    }
}

func performance(expected seconds: Double, name: String = #function) -> Bool {
    guard !_isDebugAssertConfiguration() else {
        print("[PERFORMANCE] Skipping \(name) in debug build mode")
        return false
    }
    print("[PERFORMANCE] \(name) expected: \(seconds) seconds")
    return true
}
