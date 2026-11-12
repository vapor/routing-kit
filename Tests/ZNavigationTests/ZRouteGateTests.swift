import Combine
import SwiftUI
import XCTest

@testable import ZNavigation

/// A gate that records every question the kit asks it.
///
/// Denies the routes in ``denied``; around the routes in ``withheld`` it shows a placeholder instead of the screen, the
/// way a paywall shows its lock, so a test can tell that the wrap is what ends up on screen.
@MainActor
final class NavProbeGate: ZRouteGate {
    var denied: Set<ZRoute> = []
    var withheld: Set<ZRoute> = []
    private(set) var decisions: [ZRoute] = []
    private(set) var wraps: [ZRoute] = []
    /// Every value each wrapped route's presence publisher delivered, in order.
    private(set) var presence: [ZRoute: [Bool]] = [:]
    private var subscriptions: Set<AnyCancellable> = []

    func decision(for route: ZRoute) -> ZRouteGateDecision {
        self.decisions.append(route)
        return self.denied.contains(route) ? .denied : .open
    }

    func wrap(_ screen: AnyView, for route: ZRoute, presence: AnyPublisher<Bool, Never>) -> AnyView {
        self.wraps.append(route)
        presence
            .sink { [weak self] present in self?.presence[route, default: []].append(present) }
            .store(in: &self.subscriptions)
        if self.withheld.contains(route) {
            return AnyView(Text("withheld \(route.id)").accessibilityIdentifier("withheld"))
        }
        return screen
    }

    func decisions(for route: ZRoute) -> Int { self.decisions.filter { $0 == route }.count }
    func wraps(for route: ZRoute) -> Int { self.wraps.filter { $0 == route }.count }
}

/// The gate hooks at model level, on both backends, without a window.
@MainActor
final class ZRouteGateTests: XCTestCase {
    private typealias Mini = NavMiniatureResolver

    private let backends: [ZNavigationBackend] = [.navigationStack, .navigationView]

    private func makeNavigator(
        _ backend: ZNavigationBackend,
        gate: NavProbeGate?
    ) -> (navigator: ZNavigator, resolver: NavMiniatureResolver) {
        let resolver = NavMiniatureResolver(recorder: NavProbeRecorder())
        let navigator = ZNavigator(root: Mini.home, resolver: resolver, backend: backend, staggerDelay: 0.1, gate: gate)
        return (navigator, resolver)
    }

    func testWithoutAGateEveryRouteCanPass() {
        for backend in self.backends {
            let (navigator, _) = self.makeNavigator(backend, gate: nil)
            XCTAssertNil(navigator.gate)
            XCTAssertTrue(navigator.canPass(Mini.routeA), "\(backend)")
            XCTAssertTrue(navigator.canPass(Mini.routeX), "canPass is the gate's answer only, not canRoute")
        }
    }

    func testCanPassAsksTheGateOncePerCall() {
        for backend in self.backends {
            let gate = NavProbeGate()
            gate.denied = [Mini.routeB]
            let (navigator, _) = self.makeNavigator(backend, gate: gate)
            XCTAssertTrue(navigator.gate === gate)
            XCTAssertTrue(navigator.canPass(Mini.routeA), "\(backend)")
            XCTAssertFalse(navigator.canPass(Mini.routeB), "\(backend)")
            XCTAssertEqual(gate.decisions, [Mini.routeA, Mini.routeB], "\(backend)")
            XCTAssertEqual(navigator.stack, [], "asking never navigates")
        }
    }

    func testMutationsAndTheHubNeverConsultTheGate() {
        for backend in self.backends {
            let gate = NavProbeGate()
            gate.denied = [Mini.routeA, Mini.routeB, Mini.routeC, Mini.routeD, Mini.routeE]
            let (navigator, _) = self.makeNavigator(backend, gate: gate)
            XCTAssertTrue(navigator.push("A"), "\(backend)")
            XCTAssertTrue(navigator.push(Mini.routeB), "\(backend)")
            XCTAssertTrue(navigator.replaceLast(with: Mini.routeE), "\(backend)")
            XCTAssertTrue(navigator.navigate(to: Mini.routeC), "\(backend)")
            XCTAssertTrue(navigator.setStack([Mini.routeA, Mini.routeB, Mini.routeD]), "\(backend)")
            XCTAssertTrue(navigator.popToRoot(), "\(backend)")

            let hub = ZNavigationHub()
            hub.register(navigator)
            XCTAssertTrue(hub.navigate(to: Mini.routeB) === navigator, "\(backend)")
            XCTAssertEqual(navigator.stack, [Mini.routeA, Mini.routeB], "\(backend)")
            XCTAssertEqual(gate.decisions, [], "\(backend): only a link asks for a decision")
            XCTAssertEqual(gate.wraps, [], "\(backend): the navigator itself never wraps, the destination does")
        }
    }

    func testPresenceFollowsTheStackAndDropsDuplicates() {
        for backend in self.backends {
            let (navigator, _) = self.makeNavigator(backend, gate: nil)
            var seenA: [Bool] = []
            var seenB: [Bool] = []
            let subscriptions = [
                navigator.presence(of: Mini.routeA).sink { seenA.append($0) },
                navigator.presence(of: Mini.routeB).sink { seenB.append($0) },
            ]
            XCTAssertEqual(seenA, [false], "\(backend): the current value on subscription")

            navigator.push("A")
            navigator.push("B")
            navigator.replaceLast(with: Mini.routeD)
            navigator.navigate(to: Mini.routeC)
            navigator.pop()
            navigator.popToRoot()

            XCTAssertEqual(seenA, [false, true, false], "\(backend): A stays present below every change until popToRoot")
            XCTAssertEqual(seenB, [false, true, false, true, false], "\(backend)")
            withExtendedLifetime(subscriptions) {}
        }
    }

    func testPresenceSeesASystemPopOnTheLegacyBackend() {
        let (navigator, _) = self.makeNavigator(.navigationView, gate: nil)
        navigator.navigate(to: Mini.routeB)
        XCTAssertTrue(NavPump.pump(until: { navigator.isSettled }, timeout: 3))
        var seenB: [Bool] = []
        let subscription = navigator.presence(of: Mini.routeB).sink { seenB.append($0) }
        navigator.legacyLinkDeactivated(at: 1)
        XCTAssertEqual(navigator.stack, [Mini.routeA])
        XCTAssertEqual(seenB, [true, false])
        withExtendedLifetime(subscription) {}
    }

    func testDestinationStateWrapsTheCarriedScreenOnce() {
        for backend in self.backends {
            let gate = NavProbeGate()
            let (navigator, resolver) = self.makeNavigator(backend, gate: gate)
            navigator.push("A")
            let state = ZDestinationState(route: Mini.routeA, navigator: navigator)
            guard case .ready = state.phase else { return XCTFail("\(backend): cached models render in the first frame") }
            XCTAssertEqual(gate.wraps, [Mini.routeA], "\(backend): wrapped in the same frame, once")
            XCTAssertEqual(resolver.recorder.resolveCounts["A"], 1, "\(backend)")
            XCTAssertEqual(gate.presence[Mini.routeA], [true], "\(backend): the wrap sees the route on the stack")

            navigator.pop()
            XCTAssertEqual(gate.presence[Mini.routeA], [true, false], "\(backend)")
            XCTAssertEqual(gate.wraps, [Mini.routeA], "\(backend): a pop never wraps again")
            XCTAssertEqual(gate.decisions, [], "\(backend)")
        }
    }

    func testDestinationStateWrapsTheAsyncScreenOnceTheModelsArrive() async {
        for backend in self.backends {
            let gate = NavProbeGate()
            let (navigator, resolver) = self.makeNavigator(backend, gate: gate)
            resolver.asyncRoutes = [Mini.routeB]
            resolver.asyncDelay = 0.01
            navigator.navigate(to: Mini.routeB)
            let state = ZDestinationState(route: Mini.routeB, navigator: navigator)
            guard case .loading = state.phase else { return XCTFail("\(backend): no models yet") }
            XCTAssertEqual(gate.wraps, [], "\(backend): nothing to wrap while loading")

            await state.resolveIfNeeded(using: navigator)
            guard case .ready = state.phase else { return XCTFail("\(backend): models arrived") }
            XCTAssertEqual(gate.wraps, [Mini.routeB], "\(backend)")
            XCTAssertEqual(resolver.recorder.resolveCounts["B"], 1, "\(backend)")

            await state.resolveIfNeeded(using: navigator)
            XCTAssertEqual(gate.wraps, [Mini.routeB], "\(backend): resolving again is a no-op")
        }
    }

    func testAnUnregisteredRouteIsNeverWrapped() {
        let gate = NavProbeGate()
        let (navigator, _) = self.makeNavigator(.navigationStack, gate: gate)
        let state = ZDestinationState(route: Mini.routeX, navigator: navigator)
        guard case .failed = state.phase else { return XCTFail("an unregistered route never crashes") }
        XCTAssertEqual(gate.wraps, [])
    }
}
