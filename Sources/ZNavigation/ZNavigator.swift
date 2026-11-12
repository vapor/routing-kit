import Combine
import Foundation
import Logging
import SwiftUI

/// The owner of one navigation stack.
///
/// Every mutation goes through ``setStack(_:)``, which validates the whole target with the resolver and refuses the
/// change as a whole if any entry does not resolve. The backend only decides *how* a multi-level change is
/// materialised on screen:
/// - ``ZNavigationBackend/navigationStack``: pure pushes and pure pops of any depth are assigned once; a change that
///   replaces an entry at the same depth is pop now, push after ``staggerDelay``, because `NavigationStack` drops the
///   new entry when both happen in one change.
/// - ``ZNavigationBackend/navigationView``: pops are applied at once, pushes one per run-loop turn with a delay
///   between them (the FlowStacks `withDelaysIfUnsupported` technique).
///
/// What is on screen is ``materialised``; both containers are driven by it.
///
/// ``stack`` itself is always set to the target immediately, so observers (page views, breadcrumbs) see exactly one
/// change per navigation on both backends.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class ZNavigator: ObservableObject {
    public let root: ZRoute
    public let backend: ZNavigationBackend
    public let resolver: any ZRouteResolver

    /// Delay between two consecutive pushes on the legacy backend (FlowStacks uses 0.65 s).
    public let staggerDelay: TimeInterval

    /// Consulted by ``ZRouteLink`` before a push and wrapped around every pushed screen; `nil` gates nothing.
    public let gate: (any ZRouteGate)?

    /// Pushed levels, excluding root. The only writers are ``setStack(_:)`` and the legacy link bindings.
    @Published public private(set) var stack: [ZRoute] = []

    /// The levels currently materialised on screen: the `NavigationStack` path, or the active legacy links. Equal
    /// to ``stack`` once every staggered step has run.
    @Published public private(set) var materialised: [ZRoute] = []

    /// Number of levels the legacy links have materialised.
    public var applied: Int { self.materialised.count }

    /// Human-readable reasons for refused changes, oldest first (for logs and tests).
    public private(set) var refusals: [String] = []

    private var carried: [ZRoute: ZRouteModels] = [:]
    private var pendingPushes: [Task<Void, Never>] = []
    private var lastMaterialisation: Date = .distantPast
    private var isApplying = false
    private let logger: Logger

    public init(
        root: ZRoute,
        resolver: any ZRouteResolver,
        backend: ZNavigationBackend = .automatic,
        staggerDelay: TimeInterval = 0.65,
        gate: (any ZRouteGate)? = nil,
        logger: Logger = Logger(label: "ztron.znavigation")
    ) {
        self.root = root
        self.resolver = resolver
        self.backend = backend.resolved
        self.staggerDelay = staggerDelay
        self.gate = gate
        self.logger = logger
    }

    // MARK: Queries

    /// The route on top, or ``root`` when nothing is pushed.
    public var current: ZRoute { self.stack.last ?? self.root }

    /// The segments of ``current``: what ZombieTron's `ZNavigationPath.getPath()` returns today.
    public var path: [String] { self.current.segments }

    public var depth: Int { self.stack.count }

    /// `true` when the screen shows exactly ``stack``.
    public var isSettled: Bool { self.materialised == self.stack }

    /// `true` when `route` is strictly below ``root`` and the resolver has a screen for it.
    public func canRoute(_ route: ZRoute) -> Bool {
        route.hasPrefix(self.root) && route.segments.count > self.root.segments.count && self.resolver.canResolve(route)
    }

    /// What ``gate`` decides for `route`; `true` without a gate. Asking may make the gate report a failure, so call it
    /// once per user intent, not from a view body. Nothing in the navigator calls it: ``ZRouteLink`` does, and so may
    /// a host that wants to check before `navigate(to:)`.
    public func canPass(_ route: ZRoute) -> Bool {
        switch self.gate?.decision(for: route) ?? .open {
        case .open:
            return true
        case .denied:
            return false
        }
    }

    /// `true` while `route` is on ``stack``: emits the current value on subscription, then only changes.
    public func presence(of route: ZRoute) -> AnyPublisher<Bool, Never> {
        self.$stack
            .map { $0.contains(route) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Models carried by the pushing screen, else whatever the model resolver already has synchronously.
    public func models(for route: ZRoute) -> ZRouteModels? {
        if let carried = self.carried[route] {
            return carried
        }
        return self.resolver.models.cachedModels(for: route)
    }

    // MARK: Mutations

    /// Pushes ``current`` plus one segment.
    @discardableResult
    public func push(_ segment: String, carrying models: ZRouteModels? = nil) -> Bool {
        self.push(self.current.appending(segment), carrying: models)
    }

    /// Pushes `route` on top of the stack.
    @discardableResult
    public func push(_ route: ZRoute, carrying models: ZRouteModels? = nil) -> Bool {
        if let models = models {
            self.carried[route] = models
        }
        let accepted = self.setStack(self.stack + [route])
        if !accepted {
            self.carried[route] = nil
        }
        return accepted
    }

    /// Replaces the stack with every prefix of `absolute` beyond root, so Back walks down one level at a time.
    @discardableResult
    public func navigate(to absolute: [String], carrying models: [ZRoute: ZRouteModels] = [:]) -> Bool {
        self.navigate(to: ZRoute(absolute), carrying: models)
    }

    /// Replaces the stack with every prefix of `route` beyond root, so Back walks down one level at a time.
    @discardableResult
    public func navigate(to route: ZRoute, carrying models: [ZRoute: ZRouteModels] = [:]) -> Bool {
        guard let prefixes = route.prefixes(beyond: self.root) else {
            self.refuse("navigate(to: \(route)): not below root \(self.root)")
            return false
        }
        for (carriedRoute, carriedModels) in models {
            self.carried[carriedRoute] = carriedModels
        }
        let accepted = self.setStack(prefixes)
        if !accepted {
            for carriedRoute in models.keys where !self.stack.contains(carriedRoute) {
                self.carried[carriedRoute] = nil
            }
        }
        return accepted
    }

    /// Asks the model resolver which route `key` opens (a Spotlight item, a URL slug), then navigates to it.
    @discardableResult
    public func navigate(toKey key: String, carrying models: [ZRoute: ZRouteModels] = [:]) async -> Bool {
        guard let route = try? await self.resolver.models.route(forKey: key) else {
            self.refuse("navigate(toKey: \(key)): no route for that key")
            return false
        }
        return self.navigate(to: route, carrying: models)
    }

    @discardableResult
    public func pop(_ count: Int = 1) -> Bool {
        self.pop(to: max(0, self.stack.count - max(0, count)))
    }

    /// Pops until `depth` levels remain.
    @discardableResult
    public func pop(to depth: Int) -> Bool {
        guard depth >= 0 else { return false }
        guard depth < self.stack.count else { return depth == self.stack.count }
        return self.setStack(Array(self.stack.prefix(depth)))
    }

    @discardableResult
    public func popToRoot() -> Bool {
        self.pop(to: 0)
    }

    /// Top screen swapped, depth unchanged. On the legacy backend the diff in ``setStack(_:)`` turns this into
    /// pop-then-push automatically, so a destination never changes while its link is active.
    @discardableResult
    public func replaceLast(with route: ZRoute, carrying models: ZRouteModels? = nil) -> Bool {
        guard !self.stack.isEmpty else { return self.push(route, carrying: models) }
        if let models = models {
            self.carried[route] = models
        }
        let accepted = self.setStack(Array(self.stack.dropLast()) + [route])
        if !accepted {
            self.carried[route] = nil
        }
        return accepted
    }

    /// The primitive every mutation uses. Validates every entry and refuses the whole change on the first failure
    /// (returns `false`, logs, leaves ``stack`` untouched). Nothing downstream ever force-unwraps.
    @discardableResult
    public func setStack(_ routes: [ZRoute]) -> Bool {
        for (index, route) in routes.enumerated() {
            guard route.hasPrefix(self.root), route.segments.count > self.root.segments.count else {
                self.refuse("setStack: entry \(index) '\(route)' is not below root '\(self.root)'")
                return false
            }
            guard self.resolver.canResolve(route) else {
                self.refuse("setStack: entry \(index) '\(route)' does not resolve")
                return false
            }
        }
        guard routes != self.stack else { return true }

        self.isApplying = true
        defer { self.isApplying = false }

        self.cancelPendingPushes()
        let keep = Set(routes)
        self.carried = self.carried.filter { keep.contains($0.key) }
        self.stack = routes

        switch self.backend {
        case .navigationStack, .automatic:
            self.applyStackDiff(target: routes)
        case .navigationView:
            self.applyLegacyDiff(target: routes)
        }
        return true
    }

    // MARK: NavigationStack backend materialisation

    /// `NavigationStack` applies pure pushes and pure pops of any depth in one change, but drops the new entry when a
    /// path entry is replaced in the same change (see `NavigationStackBaselineTests`). A same-depth change is
    /// therefore materialised as pop now, push after ``staggerDelay``, like on the legacy backend.
    private func applyStackDiff(target: [ZRoute]) {
        let common = zip(self.materialised, target).prefix { $0 == $1 }.count
        guard self.materialised.count > common, target.count > common else {
            self.materialised = target
            return
        }
        self.materialised = Array(self.materialised.prefix(common))
        let delay = self.staggerDelay
        let task = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, delay) * 1_000_000_000))
            guard !Task.isCancelled, let self = self, self.stack == target else { return }
            self.materialised = target
        }
        self.pendingPushes.append(task)
    }

    // MARK: Legacy backend (NavigationView) materialisation

    private func applyLegacyDiff(target: [ZRoute]) {
        let common = zip(self.materialised, target).prefix { $0 == $1 }.count
        let needsPop = self.materialised.count > common
        if needsPop {
            // All pops in one transaction: deactivating the lowest changed link pops everything above it.
            self.materialised = Array(self.materialised.prefix(common))
        }
        guard self.materialised.count < target.count else { return }

        // A push may run synchronously only when nothing was just popped and the previous push is older than the
        // stagger delay: two activations in one transaction is the iOS 15 nested-push bug.
        let sinceLast = Date().timeIntervalSince(self.lastMaterialisation)
        if !needsPop && sinceLast >= self.staggerDelay {
            self.materialiseNextLevel()
        }
        // Remaining pushes: one per run-loop turn, `staggerDelay` apart (1x, 2x, 3x ... from now).
        while self.materialised.count + self.pendingPushes.count < target.count {
            let delay = self.staggerDelay * Double(self.pendingPushes.count + 1)
            let task = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(max(0, delay) * 1_000_000_000))
                guard !Task.isCancelled, let self = self else { return }
                self.materialiseNextLevel()
            }
            self.pendingPushes.append(task)
        }
    }

    private func materialiseNextLevel() {
        let next = self.materialised.count
        guard next < self.stack.count, Array(self.stack.prefix(next)) == self.materialised else { return }
        self.materialised.append(self.stack[next])
        self.lastMaterialisation = Date()
    }

    private func cancelPendingPushes() {
        for task in self.pendingPushes {
            task.cancel()
        }
        self.pendingPushes.removeAll()
    }

    /// Called by the legacy link bindings when the system popped (back button, edge swipe) to `depth`.
    func legacyLinkDeactivated(at depth: Int) {
        // Re-entrancy: a programmatic change is in flight and already wrote the model.
        guard !self.isApplying else { return }
        // Echo of a programmatic pop: that level is already inactive in the model and the system is confirming it.
        // Acting on it would pop whatever `setStack` is about to push at the same depth (replaceLast on iOS 15).
        guard self.materialised.count > depth else { return }
        self.isApplying = true
        defer { self.isApplying = false }
        self.cancelPendingPushes()
        let target = Array(self.stack.prefix(depth))
        let keep = Set(target)
        self.carried = self.carried.filter { keep.contains($0.key) }
        self.materialised = Array(self.materialised.prefix(depth))
        self.stack = target
    }

    // MARK: NavigationStack backend binding

    /// `NavigationStack(path:)` binding over ``materialised``; an interactive pop on iOS 16+ becomes a model change
    /// like any other, while the container writing back what it already shows changes nothing.
    var stackBinding: Binding<[ZRoute]> {
        Binding(
            get: { [weak self] in self?.materialised ?? [] },
            set: { [weak self] newValue in
                guard let self = self, newValue != self.materialised else { return }
                if !self.setStack(newValue) {
                    // Refused (cannot happen for a system pop, which is always a prefix): re-publish so the
                    // container re-reads the authoritative stack.
                    self.objectWillChange.send()
                }
            }
        )
    }

    private func refuse(_ reason: String) {
        self.refusals.append(reason)
        self.logger.error("\(reason)")
    }
}
