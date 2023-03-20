import RoutingKit
import XCTest

final class RouterPerformanceTests: XCTestCase {
    func testCaseSensitivePerformance() throws {
        try performance(expected: 0.039)
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
        try performance(expected: 0.050)
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
        try performance(expected: 0.062)
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
        try performance(expected: 0.063)
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
        try performance(expected: 0.022)
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
        try performance(expected: 0.017)
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
        try performance(expected: 0.016)
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

func performance(expected seconds: Double, name: String = #function, file: StaticString = #filePath, line: UInt = #line) throws {
    try XCTSkipUnless(!_isDebugAssertConfiguration(), "[PERFORMANCE] Skipping \(name) in debug build mode", file: file, line: line)
    print("[PERFORMANCE] \(name) expected: \(seconds) seconds")
}
