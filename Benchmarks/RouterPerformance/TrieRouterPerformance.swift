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
                relative: [.p90: 5],
                absolute: [.p90: 1_000_000]
            ),
            .throughput: .init(
                relative: [.p90: 10]
            ),
        ]
    )

    Benchmark("Case-sensitive") { benchmark in
        var builder = TrieRouterBuilder(String.self)
        for letter in ["a", "b", "c", "d", "e", "f", "g"] {
            builder.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive") { benchmark in
        var builder = TrieRouterBuilder(String.self, config: .caseInsensitive)
        for letter in ["a", "b", "c", "d", "e", "f", "g"] {
            builder.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive_Match_First") { benchmark in
        var builder = TrieRouterBuilder(String.self, config: .caseInsensitive)
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae", "aaaaaaaf", "aaaaaaag"] {
            builder.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["aaaaaaaa", "42"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive_Match_Last") { benchmark in
        var builder = TrieRouterBuilder(String.self, config: .caseInsensitive)
        for letter in ["aaaaaaaa", "aaaaaaab", "aaaaaaac", "aaaaaaad", "aaaaaaae", "aaaaaaaf", "aaaaaaag"] {
            builder.register(
                letter,
                at: [
                    .constant(letter),
                    .parameter("\(letter)_id"),
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["aaaaaaag", "42"], parameters: &params)
        }
    }

    Benchmark("Case-sensitive_Minimal") { benchmark in
        var builder = TrieRouterBuilder(String.self)
        for letter in ["a"] {
            builder.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a"], parameters: &params)
        }
    }

    Benchmark("Case-insensitive_Minimal") { benchmark in
        var builder = TrieRouterBuilder(String.self, config: .caseInsensitive)
        for letter in ["a"] {
            builder.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["a"], parameters: &params)
        }
    }

    Benchmark("Minimal_Early_Fail") { benchmark in
        var builder = TrieRouterBuilder(String.self)
        for letter in ["aaaaaaaaaaaaaa"] {
            builder.register(
                letter,
                at: [
                    .constant(letter)
                ])
        }

        let router = builder.build()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var params = Parameters()
            _ = router.route(path: ["baaaaaaaaaaaaa"], parameters: &params)
        }
    }
}
