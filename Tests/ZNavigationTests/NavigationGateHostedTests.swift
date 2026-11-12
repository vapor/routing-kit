#if canImport(UIKit) && !os(watchOS)
    import Combine
    import Darwin
    import Foundation
    import SwiftUI
    import UIKit
    import XCTest

    @testable import ZNavigation

    /// The gate's touch points on screen, once per explicit backend, in a `UIWindow` + `UIHostingController`.
    ///
    /// Links are tapped for real: the root's ``ZRouteLink`` is found in the accessibility tree and activated, which
    /// runs its button action exactly as a tap does. SwiftUI only builds that tree when accessibility is on, so each
    /// scenario turns it on for the test process and restores it afterwards (``AccessibilitySwitch``). The probe gate
    /// counts every decision and every wrap.
    @MainActor
    final class NavigationGateHostedTests: XCTestCase {
        private typealias Mini = NavMiniatureResolver

        /// The root screen: one link to A, identified for the accessibility search.
        struct GateProbeRoot: View {
            var body: some View {
                VStack {
                    Text("gated root")
                    ZRouteLink("A") { Text("go to A") }
                }
                .navigationTitle("root")
            }
        }

        /// Hands the navigator a ``ZNavigationScope`` creates back to the test.
        struct ScopeProbeRoot: View {
            let capture: (ZNavigator) -> Void
            @EnvironmentObject private var navigator: ZNavigator

            var body: some View {
                GateProbeRoot()
                    .onAppear { self.capture(self.navigator) }
            }
        }

        @MainActor
        final class Host {
            let backend: ZNavigationBackend
            let recorder = NavProbeRecorder()
            let gate = NavProbeGate()
            let resolver: NavMiniatureResolver
            private(set) var navigator: ZNavigator?
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))

            /// Explicit navigator, or one owned by a ``ZNavigationScope`` when `viaScope` is true.
            init(backend: ZNavigationBackend, viaScope: Bool = false) {
                self.backend = backend
                let resolver = NavMiniatureResolver(recorder: self.recorder)
                self.resolver = resolver
                let gate = self.gate
                let content: AnyView
                if viaScope {
                    var captured: ZNavigator?
                    content = AnyView(
                        ZNavigationScope(root: Mini.home, backend: backend, gate: gate, resolver: { resolver }) {
                            ScopeProbeRoot { captured = $0 }
                        }
                    )
                    self.window.rootViewController = UIHostingController(rootView: content)
                    self.window.makeKeyAndVisible()
                    NavPump.pump(until: { captured != nil }, timeout: 5)
                    self.navigator = captured
                } else {
                    let navigator = ZNavigator(root: Mini.home, resolver: resolver, backend: backend, gate: gate)
                    self.navigator = navigator
                    content = AnyView(ZNavigationStack(navigator: navigator) { GateProbeRoot() })
                    self.window.rootViewController = UIHostingController(rootView: content)
                    self.window.makeKeyAndVisible()
                }
                NavPump.pump(0.3)
            }

            var label: String { "\(self.backend)" }

            var topTag: String {
                self.navigator?.stack.last.flatMap { self.resolver.tag(for: $0) } ?? "root"
            }

            /// Pumps until the navigator is settled and, unless the top screen is withheld or the root, it has appeared;
            /// then until the transition has been quiet for a while.
            func settle(file: StaticString = #filePath, line: UInt = #line) {
                guard let navigator = self.navigator else { return XCTFail("\(self.label): no navigator", file: file, line: line) }
                let topIsWithheld = navigator.stack.last.map { self.gate.withheld.contains($0) } ?? true
                let settled = NavPump.pump(
                    until: { navigator.isSettled && (topIsWithheld || self.recorder.mounted[self.topTag] != nil) },
                    timeout: 10
                )
                XCTAssertTrue(settled, "\(self.label): did not settle; events \(self.recorder.events)", file: file, line: line)
                NavPump.pump(0.6)
            }

            /// Activates the accessibility element labelled `label`, as a tap would.
            func tap(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
                guard let element = Self.element(labelled: label, in: self.window) else {
                    return XCTFail("\(self.label): no element '\(label)' on screen", file: file, line: line)
                }
                XCTAssertTrue(element.accessibilityActivate(), "\(self.label): '\(label)' did not activate", file: file, line: line)
            }

            /// Depth-first search through views and SwiftUI's accessibility nodes, which carry the label of their
            /// content but no identifier a cast can read.
            private static func element(labelled label: String, in object: NSObject) -> NSObject? {
                if object.isAccessibilityElement && object.accessibilityLabel == label {
                    return object
                }
                var children: [NSObject] = []
                if let view = object as? UIView {
                    children += view.subviews
                }
                if let elements = object.accessibilityElements {
                    children += elements.compactMap { $0 as? NSObject }
                } else {
                    let count = object.accessibilityElementCount()
                    if count != NSNotFound && count > 0 {
                        children += (0..<count).compactMap { object.accessibilityElement(at: $0) as? NSObject }
                    }
                }
                for child in children {
                    if let found = self.element(labelled: label, in: child) {
                        return found
                    }
                }
                return nil
            }

            func tearDown() {
                self.window.isHidden = true
                self.window.rootViewController = nil
            }
        }

        /// In-process accessibility, the switch AccessibilitySnapshot uses to make SwiftUI expose its elements.
        enum AccessibilitySwitch {
            private typealias Getter = @convention(c) () -> Bool
            private typealias Setter = @convention(c) (Bool) -> Void

            /// Sets the switch and returns its previous value, or `nil` when libAccessibility is not available.
            static func set(_ enabled: Bool) -> Bool? {
                guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW) else { return nil }
                defer { dlclose(library) }
                guard
                    let getter = dlsym(library, "_AXSApplicationAccessibilityEnabled"),
                    let setter = dlsym(library, "_AXSApplicationAccessibilitySetEnabled")
                else { return nil }
                let previous = unsafeBitCast(getter, to: Getter.self)()
                unsafeBitCast(setter, to: Setter.self)(enabled)
                return previous
            }
        }

        /// Runs `scenario` once per backend with animations off and accessibility on, restoring both afterwards.
        private func onBothBackends(viaScope: Bool = false, _ scenario: (Host, ZNavigator) -> Void) {
            let animationsWereEnabled = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            guard let accessibilityWasEnabled = AccessibilitySwitch.set(true) else {
                UIView.setAnimationsEnabled(animationsWereEnabled)
                return XCTFail("libAccessibility is unavailable: links cannot be activated")
            }
            defer {
                _ = AccessibilitySwitch.set(accessibilityWasEnabled)
                UIView.setAnimationsEnabled(animationsWereEnabled)
            }
            for backend in [ZNavigationBackend.navigationStack, .navigationView] {
                let host = Host(backend: backend, viaScope: viaScope)
                if let navigator = host.navigator {
                    scenario(host, navigator)
                } else {
                    XCTFail("\(backend): the scope never handed its navigator over")
                }
                host.tearDown()
                NavPump.pump(0.1)
            }
        }

        // MARK: - Scenarios

        // A link tap asks once and the push wraps once; a second push of the same route is a second wrap.
        func testLinkTapAsksOnceAndEveryPushWrapsOnce() {
            self.onBothBackends { host, navigator in
                host.tap("go to A")
                host.settle()
                XCTAssertEqual(navigator.stack, [Mini.routeA], host.label)
                XCTAssertEqual(host.gate.decisions, [Mini.routeA], "\(host.label): one decision per tap")
                XCTAssertEqual(host.gate.wraps, [Mini.routeA], "\(host.label): one wrap per push")
                XCTAssertEqual(host.recorder.resolveCounts["A"], 1, host.label)
                XCTAssertEqual(host.recorder.mounted["A"], "A#1", "\(host.label): the open wrap shows the screen")
                XCTAssertEqual(host.gate.presence[Mini.routeA], [true], host.label)

                navigator.pop()
                host.settle()
                XCTAssertEqual(host.gate.presence[Mini.routeA], [true, false], "\(host.label): presence ends with the pop")
                XCTAssertEqual(host.gate.wraps, [Mini.routeA], "\(host.label): popping never wraps")

                host.tap("go to A")
                host.settle()
                XCTAssertEqual(host.gate.decisions, [Mini.routeA, Mini.routeA], host.label)
                XCTAssertEqual(host.gate.wraps, [Mini.routeA, Mini.routeA], "\(host.label): a new push is a new wrap")
                XCTAssertEqual(host.recorder.mounted["A"], "A#2", host.label)
            }
        }

        // A denied tap does nothing: no push, no wrap, nothing appears.
        func testDeniedLinkTapDoesNothing() {
            self.onBothBackends { host, navigator in
                host.gate.denied = [Mini.routeA]
                let mark = host.recorder.mark()
                host.tap("go to A")
                NavPump.pump(0.6)
                XCTAssertEqual(host.gate.decisions, [Mini.routeA], "\(host.label): one decision per tap")
                XCTAssertEqual(navigator.stack, [], host.label)
                XCTAssertEqual(host.gate.wraps, [], host.label)
                XCTAssertEqual(host.recorder.lifecycle(since: mark), [], host.label)
                XCTAssertNil(host.recorder.resolveCounts["A"], host.label)
            }
        }

        // Programmatic navigation is not asked, but every screen it materialises is wrapped exactly when it resolves.
        func testProgrammaticNavigationIsWrappedButNotAsked() {
            self.onBothBackends { host, navigator in
                navigator.navigate(to: Mini.routeC)
                host.settle()
                navigator.replaceLast(with: Mini.routeD)
                host.settle()
                XCTAssertEqual(navigator.stack, [Mini.routeA, Mini.routeB, Mini.routeD], host.label)
                XCTAssertEqual(host.gate.decisions, [], "\(host.label): only a link asks")
                XCTAssertEqual(host.gate.wraps(for: Mini.routeC), 1, host.label)
                XCTAssertEqual(host.gate.wraps(for: Mini.routeD), 1, host.label)
                for (route, tag) in [(Mini.routeA, "A"), (Mini.routeB, "B"), (Mini.routeC, "C"), (Mini.routeD, "D")] {
                    XCTAssertEqual(
                        host.gate.wraps(for: route),
                        host.recorder.resolveCounts[tag] ?? 0,
                        "\(host.label): \(tag) is wrapped once per resolution"
                    )
                }
                XCTAssertEqual(host.recorder.mounted["D"], "D#1", host.label)
            }
        }

        // Models that arrive asynchronously: the screen is wrapped once, when it is built.
        func testAsyncModelsAreWrappedOnce() {
            self.onBothBackends { host, navigator in
                host.resolver.asyncRoutes = [Mini.routeB]
                host.resolver.asyncDelay = 0.2
                navigator.navigate(to: Mini.routeB)
                host.settle()
                XCTAssertEqual(host.gate.wraps(for: Mini.routeB), 1, host.label)
                XCTAssertEqual(host.recorder.resolveCounts["B"], 1, host.label)
                XCTAssertEqual(host.recorder.mounted["B"], "B#1", host.label)
                XCTAssertEqual(host.gate.decisions, [], host.label)
            }
        }

        // What the wrap returns is what is on screen: a withheld screen's body never runs.
        func testAWithheldScreenNeverRunsItsBody() {
            self.onBothBackends { host, navigator in
                host.gate.withheld = [Mini.routeA]
                host.tap("go to A")
                host.settle()
                XCTAssertEqual(navigator.stack, [Mini.routeA], host.label)
                XCTAssertEqual(host.gate.wraps, [Mini.routeA], host.label)
                XCTAssertNil(host.recorder.bodyCounts["A"], "\(host.label): the screen's body did not run")
                XCTAssertNil(host.recorder.mounted["A"], host.label)
            }
        }

        // The scope hands its gate to the navigator it owns.
        func testScopeInstallsTheGate() {
            self.onBothBackends(viaScope: true) { host, navigator in
                XCTAssertTrue(navigator.gate === host.gate, host.label)
                host.tap("go to A")
                host.settle()
                XCTAssertEqual(host.gate.decisions, [Mini.routeA], host.label)
                XCTAssertEqual(host.gate.wraps, [Mini.routeA], host.label)
                XCTAssertEqual(host.recorder.mounted["A"], "A#1", host.label)
            }
        }
    }
#endif
