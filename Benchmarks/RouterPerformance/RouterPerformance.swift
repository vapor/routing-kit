import Benchmark
import RoutingKit

let benchmarks = { @Sendable () -> Void in
    Benchmark.defaultConfiguration = .init(
        metrics: [.mallocCountTotal, .peakMemoryResident, .throughput],
        thresholds: [
            .mallocCountTotal: .init(
                relative: [.p90: 1],
                absolute: [.p90: 2]
            ),
            .peakMemoryResident: .init(
                relative: [.p90: 3],
                absolute: [.p90: 1_000_000]
            ),
            .throughput: .init(
                relative: [.p90: 10],
                absolute: [.p90: 10_000]
            ),
        ]
    )

    Benchmark("Case-sensitive") { benchmark in
        let router = TrieRouter(String.self)
        for letter in ["a", "b", "c", "d", "e", "f", "g"] {
            router.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a", "b", "c", "d", "e", "f", "g"] {
            router.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive_Match_First") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae", "aaaaaaaf", "aaaaaaag"] {
            router.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["aaaaaaaa", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive_Match_Last") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae", "aaaaaaaf", "aaaaaaag"] {
            router.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["aaaaaaag", "42"], parameters: &params)
        }
    }

    Benchmark("Case-sensitive_Minimal") { benchmark in
        let router = TrieRouter.init(String.self)
        for letter in ["a"] {
            router.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive_Minimal") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a"] {
            router.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a"], parameters: &params)
        }
    }

    Benchmark("Minimal_Early_Fail") { benchmark in
        let router = TrieRouter.init(String.self)
        for letter in ["aaaaaaaaaaaaaa"] {
            router.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        router.makeImmutable()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["baaaaaaaaaaaaa"], parameters: &params)
        }
    }
}
