import Combine
import SwiftUI

/// A link that appends a value to the navigator instead of building a destination.
///
/// A `Button` on both backends, deliberately: `NavigationLink(value:)` would behave identically on iOS 16 but has
/// no counterpart on iOS 15, and a button is the only form whose destination is never evaluated eagerly. This single
/// change removes the per-render route lookups for every visible link.
///
/// With a ``ZRouteGate`` installed, a tap asks ``ZNavigator/canPass(_:)`` once before pushing and does nothing when the
/// gate denies: the gate reports its own failure. The disabled state reflects ``ZNavigator/canRoute(_:)`` only, so
/// rendering a link never consults the gate.
///
/// Reads the ``ZNavigator`` that ``ZNavigationStack`` puts in the environment.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct ZRouteLink<Label: View>: View {
    private enum Target {
        case segment(String)
        case route(ZRoute)
    }

    private let target: Target
    private let carrying: ZRouteModels?
    private let label: Label
    @EnvironmentObject private var navigator: ZNavigator

    /// A link to the current route plus `segment`.
    public init(_ segment: String, carrying: ZRouteModels? = nil, @ViewBuilder label: () -> Label) {
        self.target = .segment(segment)
        self.carrying = carrying
        self.label = label()
    }

    /// A link to the absolute `route`.
    public init(to route: ZRoute, carrying: ZRouteModels? = nil, @ViewBuilder label: () -> Label) {
        self.target = .route(route)
        self.carrying = carrying
        self.label = label()
    }

    private var destination: ZRoute {
        switch self.target {
        case .segment(let segment):
            return self.navigator.current.appending(segment)
        case .route(let route):
            return route
        }
    }

    public var body: some View {
        Button {
            let destination = self.destination
            guard self.navigator.canPass(destination) else { return }
            self.navigator.push(destination, carrying: self.carrying)
        } label: {
            self.label
        }
        .buttonStyle(.plain)
        .disabled(!self.navigator.canRoute(self.destination))
        .accessibilityAddTraits(.isLink)
    }
}
