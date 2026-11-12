# Unified navigation design

One navigation interface over `NavigationStack` and `NavigationView`, hosted in this package so that ZombieTron
adopts it as a dependency instead of carrying a prototype in its test target.

## Overview

Status: design, 2026-10-26. The library is the `ZNavigation` target (product `ZTronNavigationKit`); the parity suite
is `Tests/ZNavigationTests`. Two decisions shape everything below:

- **`ZTronAppShield` is not replaced.** The shell includes tab bar, glare, toolbar, keyboard and safe-area behaviour
  that `NavigationView` does not offer. The kit plugs into the view modifier that creates the navigation container
  today (`withAppropriateNavigationView()`), and the shell keeps `initialView`, `initialPath`, its tabs and its
  environment injection exactly as they are. See section 5.
- **The kit knows nothing about games, maps and tools.** ``ZRouteModels`` is a type-erased bag of environment
  objects; the app decides what a screen needs, the pushing screen carries it, the destination injects it. The
  database-backed model resolver stays in the app, where `ZTronDataModel` and `SQLite` live.

Not to be confused with `ZTronNavigator` in the separate `ZTronRouter` package, which walks the trie itself and has
nothing to do with screens.

## 1. Objective

The app already resolves *what* to show through a trie router keyed by string paths. What it lacks is an owner of
*where the user is*: the stack lives inside SwiftUI's `NavigationStack` (iOS 16+) or `NavigationView` (iOS 15),
nothing can push or pop programmatically, and the breadcrumb `ZNavigationPath` is a label rather than state.

The objective is **one interface whose observable behaviour is identical on both backends**:

| Operation | Must behave identically on `NavigationStack` and `NavigationView` |
| --- | --- |
| `push(segment)` / `push(route)` | appends one level, destination resolved once, back button pops exactly it |
| `navigate(to: absolutePath)` | replaces the stack with every prefix of the path, so Back walks down level by level |
| `pop()`, `pop(to: depth)`, `popToRoot()` | model and screen agree immediately; no intermediate flashes of other levels |
| `replaceLast(with:)` | top screen swapped, depth unchanged |
| interactive back (button, edge swipe) | writes into the navigator; model never disagrees with the screen |
| destination resolution | one `screen(for:)` for both backends, evaluated once per push, never for inactive links |
| identity | `@State` / `@StateObject` of a pushed screen survive parent re-renders, tab switches and rotation |
| lifecycle | one "page view" per path change, emitted by the navigator, not by `onAppear` |
| tabs | one navigator per tab; switching tabs preserves each stack |
| failure | an unresolvable path never crashes; `canRoute(_:)` answers the same on both backends |

Everything that differs between the backends is hidden inside one container view. The existing `registerView(path:)`
registrations are **not edited**.

## 2. Model

### 2.1 `ZRoute`: one stack entry is the full absolute path up to that level

`navigationDestination(for:)` receives the value alone, without its index in the stack, so the value must carry
everything needed to resolve it. A route is therefore the absolute path, not a single segment. Hashing on the full
path gives the identity rule for free: the same path is always the same screen identity, and two different maps
never share one (today every leaf map of a game shares `.id(gameData.getName())`).

`ZRoute` is `Hashable`, `Codable`, `Sendable`, `Identifiable` (its `id` is the segments joined by `/`, also the
analytics page name) and expressible as an array literal: `[">", "home", "black ops 7"]`.

### 2.2 `ZNavigator`: the owner of one stack

Rules that make the behaviour identical on both backends:

1. `setStack(_:)` validates every entry (strictly below `root`, and `resolver.canResolve`) and refuses the whole
   change if one fails: returns `false`, records the reason in `refusals`, logs it, leaves `stack` untouched.
   Nothing downstream ever force-unwraps.
2. `navigate(to:)` expands the absolute path into **all its prefixes beyond root**, so Back always walks down one
   level. For `[">", "home", "black ops 3", "zombies chronicles", "ascension", tool]` that is four entries.
3. `setStack` writes `stack` once, immediately, so observers see one change per navigation. What is on screen is
   `materialised`, and both containers are driven by it. On the `navigationStack` backend a pure push or a pure pop of
   any depth is one assignment; a change that replaces an entry at the same depth (`replaceLast`, a jump to another
   branch) is pop now, push after `staggerDelay`, because `NavigationStack` drops the new entry when both happen in one
   change (`NavigationStackBaselineTests` records this on the iOS 17.5 simulator). On the `navigationView` backend the
   **diff** is applied in the only order iOS 15 tolerates: all pops at once (deactivating the lowest changed link pops
   everything above it in one transaction), then pushes **one per run-loop turn with `staggerDelay`** between them,
   the FlowStacks `withDelaysIfUnsupported` technique. The visible difference: a three-level deep link animates in
   three steps on iOS 15 and lands in one step on iOS 16+. The system's own confirmation that a level was popped is
   recognised as an echo (that level is already inactive in `materialised`) and never mistaken for a user pop.
4. The navigator is created **once** per tab (a `@StateObject`, owned by ``ZNavigationScope``) and injected as an
   environment object by ``ZNavigationStack``. It replaces today's per-render `ZNavigationPath` instances, so re-render
   churn stops at the source.

Carried models (`push(_:carrying:)`, `navigate(to:carrying:)`) live in the navigator until their route leaves the
stack. `navigate(toKey:)` asks the model resolver which route an external key (a Spotlight item) opens.

### 2.3 `ZNavigationBackend`

`automatic` picks `NavigationStack` where it exists, else `NavigationView`. The explicit cases exist for one reason:
**parity must be testable on the simulators available**, which all run iOS 17 or later. The same scenario suite runs
against `navigationStack` and `navigationView` and must produce the same stack, the same identities and the same
appear/disappear sequences.

### 2.4 Resolvers: from a route to a screen, with the models that screen needs

Today every pushed screen of ZombieTron depends on environment objects that only its pushing parent can supply from
models it loaded itself:

| Level | Screen | Needs from parent |
| --- | --- | --- |
| `>/home/:game` | `ZTronMapSelection` | `SerializedGameModel`, `ZTronMapProvider(nil)` |
| `>/home/:game/<collection>` | `ZTronMapSelection` | game, `ZTronMapProvider(collection map)` |
| `>/home/:game/(<collection>/):map` | `ZTronMapToolsPicker` | game, `ZTronMapProvider(map)` (force-unwrapped today) |
| `…/:tool` | tool view | nothing beyond app-level objects (the `map`/`tool` injections have no readers) |

Two protocols separate the two sources of a destination's needs:

- ``ZRouteResolver``: `canResolve(_:)` (trie lookup), `screen(for:)` (the registered closure **plus the parameters the
  lookup filled**, because the closures read `parameters.get("game")`), `models`, and `scope(for:)` (objects created
  once per push and stable for the destination's lifetime; section 4 uses it for the compatibility breadcrumb).
  ``ZTrieRouteResolver`` wraps the app's `TrieRouter<(Parameters) -> any View>` without touching a registration.
- ``ZRouteModelResolver``: path to models when nothing was carried (deep links, restoration). `cachedModels(for:)` is
  the synchronous fast path that lets a destination render in its first frame; `models(for:)` is the async path;
  `route(forKey:)` maps a Spotlight key to a full route.

"Carried" models need no resolver: when `ZTronHome` pushes a game it already holds the `SerializedGameModel`, so it
passes it along (`push(game.getName(), carrying: ZRouteModels(game, ZTronMapProvider(wrappedValue: nil)))`) and the
destination renders immediately, exactly like today. The database-backed resolver (`CRUD.readAllGames`,
`readAllMaps` / `readAllSubmaps`, the tabs read used by `ZTronMapToolsPicker`, and a cached tool-key table for
Spotlight) is an app type conforming to ``ZRouteModelResolver``; it does not belong in this package.

Pitfall worth naming: with an optional return type, `.none` is `Optional.none`, not "no models needed". The bag's
empty value is therefore spelled ``ZRouteModels/empty``.

### 2.5 `ZRouteDestinationView`: resolve once per push, inject once per push

The destination's state is a `@StateObject` created once per identity, which is once per push on both backends. Its
initialiser does the trie lookup, takes carried or cached models and invokes the registered closure **once**; a deep
link without models shows a `ProgressView` until the async resolver answers, then invokes the closure once. A route
with no registration or failing models shows an "unavailable" view, never a crash. The resolved screen receives its
models and the resolver's `scope(for:)` objects as environment objects. The registered closures are untouched: they
still return `any View` and still rely on environment objects, which this view now provides.

The screen is kept type-erased. The trie returns `any View`, so erasure to `AnyView` happens at this boundary whichever
way the screen is rendered; keeping the erased value in the destination state is what makes "once per push" a
guarantee rather than a side effect of SwiftUI's diffing, and `NavigationStackBaselineTests` pushes screens through a
destination that stores its screen exactly like this (with and without identity and task modifiers) and sees every
screen's state created once. What did re-create a pushed screen's state on the `NavigationStack` backend was an
explicit `.id(route)` inside this shared view while the container re-rendered during the push. Identity is therefore
given by the containers: `NavigationStack` hosts one destination per path entry, and the legacy chain applies
`.id(route)` to each level, so a new route at the same depth is a new screen.

### 2.6 `ZRouteLink`: a link that appends a value instead of building a destination

A `Button` on **both** backends, deliberately: `NavigationLink(value:)` would behave identically on iOS 16 but has no
counterpart on iOS 15, and a button is the only form whose destination is never evaluated eagerly. The link is
disabled when `canRoute` says the destination does not resolve. This single change removes the per-render route
lookups for every visible link (N games, M maps, T tools).

### 2.7 `ZRouteGate`: the boundary for something outside the kit

The kit does not know what a paywall is. It declares ``ZRouteGate``, which the host conforms its own engine to and
passes as `gate:` to ``ZNavigator`` or ``ZNavigationScope``. `gate == nil` is the default and changes nothing: no hook
runs and the parity suite is untouched. With a gate there are exactly two touch points: ``ZRouteLink`` asks
`decision(for:)` once per tap and does nothing on `.denied`, and the destination wraps the resolved screen with
`wrap(_:for:presence:)` once per push, on the carried and on the async path. `presence` is
``ZNavigator/presence(of:)``, `true` while the route is on the stack, because the two backends deliver
`onDisappear` at different moments. `push`, `navigate(to:)` and the hub do not ask: the wrap catches whatever they
materialise, and ``ZNavigator/canPass(_:)`` lets a host ask first. `NavigationGateHostedTests` taps the real link on
both backends and counts decisions and wraps with a probe gate.

## 3. The container

``ZNavigationStack`` takes an existing navigator; ``ZNavigationScope`` creates and owns one for its lifetime and
registers it with the ``ZNavigationHub`` in the environment, which is the shape a view modifier needs (section 5).
On the `navigationStack` backend the container is `NavigationStack(path:)` bound to the navigator's `materialised`
levels, with one `navigationDestination(for: ZRoute.self)`. On the legacy backend it is `NavigationView` in stack style
around a recursive chain of levels, each one its content plus **one** hidden `isActive` link whose destination is the
next level, built lazily and given the identity of its route.

Known `NavigationView` pitfalls and how each is neutralised:

| Pitfall (iOS 15) | Handling |
| --- | --- |
| activating several nested `isActive` links in one transaction pops back / only the first animates | `setStack` staggers pushes on this backend (one per `staggerDelay`), pops are applied together |
| a link that disappears from the hierarchy while active pops its destination | the hidden link is always in the content's background, never conditional, never in a lazy container |
| `destination` evaluated eagerly builds the whole next level on every parent render | the destination is wrapped in a lazy view; the destination state resolves once in its `@StateObject` |
| "Unable to present. Please file a bug." when a destination changes while active | `replaceLast` is pop-then-push on this backend, through the diff |
| back-swipe leaves the model stale | the link binding's setter pops the navigator to its depth, guarded against re-entrancy |
| a lone hidden `isActive` link can pop itself (iOS 14.5–15) | a second inert link sits next to it |
| pop-to-root when a parent's state changes | the parent no longer re-creates destinations; identity is the route value |

`NavigationStack` has one pitfall of its own, found by the baseline test: replacing a path entry in a single change
pops the old screen and never presents the new one. The two-step diff of section 2.2 is the workaround.

What cannot be made identical: animation granularity of multi-level jumps (see 2.2). The parity suite asserts the
end state, the identities and the sequence of appearances, not frame-by-frame animation.

## 4. Analytics, Pro Tips and the compatibility breadcrumb

- `ZNavigationPath` keeps existing in the app as a **read-only compatibility object**: the app's resolver returns one
  from `scope(for:)` (`ZTrieRouteResolver(router:models:scope:)`), so every destination gets one stable breadcrumb for
  its lifetime and `sendViewAnalytics()`, `ProTipsSheet` and the sheet header keep compiling and reading the right
  path. No change to the route files that attach `.sendViewAnalytics()`.
- The authoritative page-view signal moves to the navigator: ``ZPageViewReporter`` subscribes to the stack, emits the
  top route's `id` once per change, and is the same code on both backends. Once it is wired to Mixpanel,
  `.sendViewAnalytics()` becomes a no-op modifier and is removed from the route files in one mechanical pass. This
  replaces today's `onAppear` counting (fires again on every return) and the throttled publisher that drops events
  during fast navigation.
- Pro Tips reads `navigator.current.segments` instead of the environment breadcrumb when the sheet is migrated; until
  then the compatibility object serves it.

## 5. Shell, tabs, deep links

`ZTronAppShield` stays as it is. The only place the app creates a navigation container is the
`withAppropriateNavigationView()` modifier, applied once per tab inside the shell, and that modifier is where the kit
is installed:

```swift
// ZombieTron: View + withAppropriateNavigationView.swift
import ZNavigation

extension View {
    func withAppropriateNavigationView(root: ZRoute = [">", "home"]) -> some View {
        self.modifier(AppropriateNavigationView(root: root))
    }
}

private struct AppropriateNavigationView: ViewModifier {
    let root: ZRoute
    @EnvironmentObject private var routingService: RoutingServiceProvider

    func body(content: Content) -> some View {
        let routing = self.routingService
        return ZNavigationScope(root: self.root, resolver: {
            ZTrieRouteResolver(
                router: routing.router,
                models: DatabaseModelResolver(),
                scope: { ZRouteModels(ZNavigationPath.compat($0)) }
            )
        }) {
            content.appToolbar()
        }
    }
}
```

- The modifier keeps its iOS 15 appearance setup. `ZNavigationScope` owns the tab's navigator (`@StateObject`, one per
  tab), so the shell does not need to.
- `initialView` / `initialPath` in the shell are unchanged: the resolved Home view is simply the root content of the
  container. The shell's own re-renders no longer rebuild destinations, because destinations are owned by the
  navigator, not by the links (parity scenario 6).
- The About tab gets its own root (`withAppropriateNavigationView(root: [">", "about"])`, one argument at the call
  site) so that two navigators never share a root in the hub; with no routes registered below `>/about` its links
  are simply disabled.
- Deep links need a receiver that is not the shell. `ZombieTronApp` creates a ``ZNavigationHub``, installs it with
  `.zNavigationHub(hub)` on the shield (a modifier outside the shield, next to the existing `environmentObject` calls)
  and handles Spotlight continuation there:

```swift
// ZombieTron: ZombieTronApp.swift
@StateObject private var navigationHub = ZNavigationHub()

ZTronAppShield()
    .zNavigationHub(self.navigationHub)
    .onContinueUserActivity(CSSearchableItemActionType) { activity in
        guard let key = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
        Task { await self.navigationHub.navigate(toKey: key) }
    }
```

  The stored Spotlight metadata is not needed: the item's unique identifier is the tool key, and the app's
  `route(forKey:)` recovers game, collection and map from the database. A navigation that arrives before its tab's
  navigator exists (cold start) is kept by the hub and replayed on registration.
- All Spotlight content lives under `>/home`, the tab the shell shows by default. Switching to another tab for a deep
  link would need the shell to observe the hub; nothing today needs it, and it is out of scope.
- URL schemes and state restoration are the same primitive: parse to segments, `hub.navigate(to:)`; encode
  `navigator.stack` (`Codable`) in `SceneStorage` to restore.

## 6. Migration (registrations unchanged)

Order of work on the app side, each step shippable on its own. The step-by-step routine with the code for each step
is <doc:ZombieTronAdoption>.

1. Depend on the `ZTronNavigationKit` product of this package next to `ZTronRoutingKit`; `import ZNavigation`.
2. Add the app's `DatabaseModelResolver` (conforming to ``ZRouteModelResolver``) and the `ZNavigationPath.compat(_:)`
   helper that builds a breadcrumb from a route using only the class's public API.
3. Re-implement `AppropriateNavigationView` on `ZNavigationScope` as in section 5. Nothing else changes yet: the
   existing `NavigationLink(destination:)` sites still work inside both backends.
4. Migrate Home, map selection and tools picker to ``ZRouteLink``, carrying the models they already hold
   (three files, about sixty lines removed). `routeAvailabilityCache` in the tools picker becomes
   `navigator.canRoute`.
5. Install the hub and the Spotlight continuation handler in `ZombieTronApp`; implement `route(forKey:)`.
6. Move page views to ``ZPageViewReporter``; make `.sendViewAnalytics()` a no-op; delete the dead `droppingLast`
   and the duplicate environment injection.
7. When iOS 15 is dropped, nothing in the app changes; the legacy backend is deleted here, in the kit.

## 7. Behaviour under the review's questions

| Question | Today | With ZNavigation |
| --- | --- | --- |
| Programmatic navigation | impossible: no path owner, no binding, no activation hook | `navigate / push / pop / popToRoot / replaceLast / setStack`, hub for Spotlight, URLs, restoration |
| Stability of view selection | identity stable, instances churn every shell render | identity = route value; instances created once per push |
| Redundant re-renders | every shell render re-resolves routes and re-injects a fresh breadcrumb; N+M+T destination builds per render | destinations built once; links are buttons; the navigator publishes only on navigation |
| State loss | not observed today, but one `.id` / type change away | explicit identity rule; parity test for `@StateObject` survival on both backends |
| Lifecycle | `onAppear`-driven analytics double counts and is throttled | one page view per path change from the navigator; lifecycle sequences asserted equal across backends |
| iOS 15 | `NavigationView` with eager destinations and no programmatic lever | legacy backend with staggered pushes, identical end state and API |

## 8. Parity tests

`Tests/ZNavigationTests` has two layers:

- `ZNavigatorTests`, `ZRouteTests`, `ZRouteModelsTests`: the model without a window, on both backends, including the
  legacy staggering (run with a short delay and a pumped run loop). They run with `swift test` on macOS and on CI.
- `NavigationParityTests`: each scenario runs twice, once per explicit backend, in a `UIWindow` +
  `UIHostingController` with the run loop pumped between steps and animations disabled, against a miniature resolver
  (three levels, probe screens that record `init`, `onAppear`, `onDisappear`, body counts and expose a probe
  identifier). `NavigationStackBaselineTests` hosts a plain `NavigationStack` the same way. Both need an iOS
  simulator:

```sh
xcodebuild test -scheme ztron-routing-kit-Package \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:ZNavigationTests
```

Scenarios: (1) push one level; (2) three levels via `navigate(to:)`, then back; (3) `popToRoot` from depth 3;
(4) interactive back through `UINavigationController.popViewController` on the hosted controller; (5) `replaceLast`;
(6) shell re-render churn, ten times, with two levels pushed; (7) tab switch and back; (8) unresolvable route;
(9) identity is the path (pop and re-push yields a fresh screen); (10) deep link whose models arrive asynchronously.

Always asserted equal across backends: the final stack and the probe identifier of the top screen. Also asserted
equal, except for the two multi-level jumps: init counts, resolve counts and the sequence of `onAppear` events. Every
scenario prints a `PARITY` line with its full report, and `NavigationStackBaselineTests` prints `BASELINE` lines for a
plain `NavigationStack` with the same probe screens, so differences are documented from data and attributed to SwiftUI
or to the kit.

Documented as unequal (iOS 17.5 simulator, hostless test runner):

- Multi-level jumps: the legacy backend materialises the levels one at a time, so A, B and C appear in that order;
  `NavigationStack` shows the top screen first and the intermediate ones only when Back reveals them.
- When a covered or popped screen receives `onDisappear` differs between the backends, and the hosted runner defers
  it until the next transition. Nothing in the kit depends on it, which is why page views come from the navigator
  (section 4) and not from `onAppear` / `onDisappear`.
- Not verifiable on a current Mac: true iOS 15 runtime behaviour (no iOS 15 simulator runtime can be installed).

## 9. Risks and open points

- The staggering delay on the legacy backend is a heuristic (FlowStacks uses 0.65 s); too short re-introduces the
  nested-push bug on real iOS 15 devices, which cannot be tested here. With animations enabled it must exceed the
  push animation: the parity suite saw a 0.3 s stagger pop the whole stack on the iOS 17.5 simulator.
- A same-depth replacement is two transitions on both backends (pop, then push after `staggerDelay`). On iOS 16+
  this works around `NavigationStack` dropping the new entry; re-check it when the deployment target moves.
- `BottomSheet`, `introspect(.tabView)` and `appToolbar()` have been exercised only inside the current containers;
  the legacy backend keeps `NavigationView(.stack)`, so toolbar behaviour should not change, but it must be checked
  on device.
- `ZNavigationPath` remains as a compatibility shim until analytics and Pro Tips read the navigator; two sources of
  truth exist during the transition (both derived from the same route, so they cannot disagree).
- ``ZRouteModels`` keeps one object per dynamic type, which is exactly what an environment can expose; two providers
  of the same type for one screen were never possible before either.
- The hub cannot switch tabs: the shell's `activeTab` is private state. Fine while every deep link targets Home.
- The design keeps `(Parameters) -> any View` as the trie output. A later step could make registrations return a
  typed screen (view plus declared model requirements), which would let `canRoute` also check that the required
  models exist, but that touches every route file and is out of scope.
