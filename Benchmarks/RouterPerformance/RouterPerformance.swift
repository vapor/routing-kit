import Benchmark
import RoutingKit

let benchmarks = { @Sendable () -> Void in
    Benchmark.defaultConfiguration = .init(
        metrics: [.mallocCountTotal, .peakMemoryResident, .throughput],
        thresholds: [
            .mallocCountTotal: .init(
                relative: [.p90, 1],
                absolute: [.p90, 2]
            ),
            .peakMemoryResident: .init(
                relative: [.p90: 3],
                absolute: [.p90: 1_000_000]
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

        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive Match First") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae", "aaaaaaaf", "aaaaaaag"] {
            router.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["aaaaaaaa", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive Match Last") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae", "aaaaaaaf", "aaaaaaag"] {
            router.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["aaaaaaag", "42"], parameters: &params)
        }
    }

    Benchmark("Case-sensitive Minimal") { benchmark in
        let router = TrieRouter.init(String.self)
        for letter in ["a"] {
            router.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive Minimal") { benchmark in
        let router = TrieRouter.init(String.self, options: [.caseInsensitive])
        for letter in ["a"] {
            router.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a"], parameters: &params)
        }
    }

    Benchmark("Minimal Early Fail") { benchmark in
        let router = TrieRouter.init(String.self)
        for letter in ["aaaaaaaaaaaaaa"] {
            router.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["baaaaaaaaaaaaa"], parameters: &params)
        }
    }
}
