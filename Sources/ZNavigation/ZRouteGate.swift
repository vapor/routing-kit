import Combine
import SwiftUI

/// The smallest protocol that lets something outside the kit gate a route.
///
/// The kit knows nothing about what a gate checks (a subscription, a token balance, a feature flag); it only asks two
/// questions at two moments. The host conforms its own engine and installs it with the `gate:` parameter of
/// ``ZNavigator/init(root:resolver:backend:staggerDelay:gate:logger:)`` or
/// ``ZNavigationScope/init(root:backend:staggerDelay:gate:resolver:content:)``. Without a gate every hook is a no-op
/// and the navigator behaves exactly as it does without this protocol.
///
/// Where the kit consults the gate:
/// - ``ZRouteLink`` calls ``decision(for:)`` once per tap, before pushing, and does nothing on
///   ``ZRouteGateDecision/denied``: the gate has already reported its own failure.
/// - The destination of every push wraps the resolved screen with ``wrap(_:for:presence:)``, once per push, whether
///   its models were carried or loaded asynchronously.
///
/// `ZNavigator.push`, `ZNavigator.navigate(to:)` and the ``ZNavigationHub`` do not consult the gate: the wrap catches whatever they materialise, and
/// ``ZNavigator/canPass(_:)`` is there for callers that want to ask first.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol ZRouteGate: AnyObject {
    /// Before a link pushes `route`. A route the gate does not know is ``ZRouteGateDecision/open``.
    func decision(for route: ZRoute) -> ZRouteGateDecision

    /// Around the screen resolved for `route`, once per push. `presence` is `true` while `route` is on the stack.
    func wrap(_ screen: AnyView, for route: ZRoute, presence: AnyPublisher<Bool, Never>) -> AnyView
}

/// What a ``ZRouteGate`` says about a route before a link pushes it.
public enum ZRouteGateDecision: Sendable {
    /// The link pushes.
    case open
    /// The link does nothing.
    case denied
}
