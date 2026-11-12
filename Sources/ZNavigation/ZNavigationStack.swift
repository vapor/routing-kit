import Combine
import Foundation
import SwiftUI

/// The one container that hides the backend.
///
/// Everything above it (navigator, routes, links, destination view) is shared; only this file knows whether a
/// `NavigationStack` or a `NavigationView` with a recursive chain of hidden `isActive` links is on screen. Install it
/// wherever the app creates its navigation container today. In ZombieTron that is the `withAppropriateNavigationView`
/// modifier, not `ZTronAppShield`, whose tab bar, glare, toolbar and keyboard behaviour stay exactly as they are.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct ZNavigationStack<Root: View>: View {
    @ObservedObject private var navigator: ZNavigator
    private let root: Root

    public init(navigator: ZNavigator, @ViewBuilder root: () -> Root) {
        self.navigator = navigator
        self.root = root()
    }

    public var body: some View {
        self.container
            .environmentObject(self.navigator)
    }

    @ViewBuilder
    private var container: some View {
        switch self.navigator.backend {
        case .navigationStack:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                NavigationStack(path: self.navigator.stackBinding) {
                    self.root.navigationDestination(for: ZRoute.self) { route in
                        ZRouteDestinationView(route: route, navigator: self.navigator)
                    }
                }
            } else {
                self.legacy
            }
        case .navigationView, .automatic:
            self.legacy
        }
    }

    private var legacy: some View {
        ZLegacyNavigationView {
            ZLegacyLevel(depth: 0, navigator: self.navigator) { self.root }
        }
    }
}

/// Creates and owns one ``ZNavigator`` for its lifetime (one per tab), registers it with the ``ZNavigationHub`` in
/// the environment if there is one, and renders a ``ZNavigationStack``.
///
/// For containers that cannot own a `@StateObject` built from environment objects, such as a view modifier whose
/// resolver comes from an environment object: the `resolver` closure runs once, on the first render. `gate`, if any,
/// is handed to the navigator (see ``ZRouteGate``).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct ZNavigationScope<Root: View>: View {
    @StateObject private var navigator: ZNavigator
    @Environment(\.zNavigationHub) private var hub
    private let root: Root

    public init(
        root: ZRoute,
        backend: ZNavigationBackend = .automatic,
        staggerDelay: TimeInterval = 0.65,
        gate: (any ZRouteGate)? = nil,
        resolver: @escaping () -> any ZRouteResolver,
        @ViewBuilder content: () -> Root
    ) {
        self._navigator = StateObject(
            wrappedValue: ZNavigator(
                root: root,
                resolver: resolver(),
                backend: backend,
                staggerDelay: staggerDelay,
                gate: gate
            )
        )
        self.root = content()
    }

    public var body: some View {
        ZNavigationStack(navigator: self.navigator) { self.root }
            .onAppear { self.hub?.register(self.navigator) }
    }
}

/// `NavigationView` in stack style where that style exists (it does not on macOS).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ZLegacyNavigationView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        #if os(macOS)
            NavigationView { self.content }
        #else
            NavigationView { self.content }
                .navigationViewStyle(.stack)
        #endif
    }
}

/// One level of the legacy chain: its content plus ONE hidden `isActive` link whose destination is the next level.
///
/// The link is always present in the content's background, never inside a lazy container and never conditional,
/// because a link that disappears while active pops its destination.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
struct ZLegacyLevel<Content: View>: View {
    let depth: Int
    @ObservedObject var navigator: ZNavigator
    let content: () -> Content

    init(depth: Int, navigator: ZNavigator, @ViewBuilder content: @escaping () -> Content) {
        self.depth = depth
        self.navigator = navigator
        self.content = content
    }

    /// Reads ``ZNavigator/applied`` (the materialised count), not the stack count: see the staggering in ZNavigator.
    private var isActive: Binding<Bool> {
        Binding(
            get: { self.navigator.applied > self.depth },
            set: { active in
                if !active {
                    self.navigator.legacyLinkDeactivated(at: self.depth)
                }
            }
        )
    }

    var body: some View {
        self.content()
            .background(
                ZStack {
                    NavigationLink(isActive: self.isActive) {
                        // Real laziness: NavigationLink evaluates `destination` eagerly.
                        ZLazyView(self.nextLevel)
                    } label: {
                        EmptyView()
                    }
                    // iOS 14.5-15 quirk: a lone hidden isActive link can pop itself; a second inert link avoids it.
                    NavigationLink(destination: EmptyView()) { EmptyView() }
                }
                .hidden()
                .frame(width: 0, height: 0)
            )
    }

    @ViewBuilder
    private var nextLevel: some View {
        // `materialised`, not `stack`: during a pop-then-push the popped level must keep showing the OLD route
        // until its link has deactivated; the new route is only mounted by the staggered push.
        if self.navigator.materialised.indices.contains(self.depth) {
            let route = self.navigator.materialised[self.depth]
            ZLegacyLevel<ZLegacyDestination>(depth: self.depth + 1, navigator: self.navigator) {
                ZLegacyDestination(route: route, navigator: self.navigator)
            }
        } else {
            EmptyView()
        }
    }
}

/// The destination of one legacy level: the shared destination view with the identity of its route, so that a new
/// route at the same depth is a new screen (the `NavigationStack` backend gets that from its per-entry hosting).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ZLegacyDestination: View {
    let route: ZRoute
    let navigator: ZNavigator

    var body: some View {
        ZRouteDestinationView(route: self.route, navigator: self.navigator)
            .id(self.route)
    }
}

/// Defers building its content until SwiftUI asks for the body.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ZLazyView<Content: View>: View {
    private let build: () -> Content

    init(_ build: @escaping @autoclosure () -> Content) {
        self.build = build
    }

    var body: Content { self.build() }
}
