# ``ZNavigation``

One navigation interface over `NavigationStack` and `NavigationView`, driven by the routes of a `TrieRouter`.

## Overview

ZombieTron resolves *what* to show through a trie router keyed by string paths (the `RoutingKit` target of this
package). `ZNavigation` adds the owner of *where the user is*: a ``ZNavigator`` holds one stack of ``ZRoute`` values,
``ZNavigationStack`` renders it on `NavigationStack` (iOS 16+) or on `NavigationView` with a chain of hidden
`isActive` links (iOS 15), and ``ZRouteLink`` pushes a value instead of building a destination.

The observable behaviour is identical on both backends: push, pop, deep links, interactive back, destination
resolution (once per push), identity, lifecycle and failure handling. The design and the parity suite that proves
it are described in <doc:UnifiedNavigationDesign>.

```swift
import RoutingKit
import ZNavigation

let router = TrieRouter<(Parameters) -> any View>()
router.register({ _ in HomeScreen() }, at: [">", "home"])
router.register({ parameters in GameScreen(name: parameters.get("game")!) }, at: [">", "home", ":game"])

struct Shell: View {
    var body: some View {
        ZNavigationScope(root: [">", "home"], resolver: { ZTrieRouteResolver(router: router) }) {
            HomeScreen()
        }
    }
}

struct HomeScreen: View {
    var body: some View {
        ZRouteLink("black ops 7") { Text("Black Ops 7") }
    }
}
```

## Topics

### Routes and the navigator

- ``ZRoute``
- ``ZNavigator``
- ``ZNavigationBackend``

### Resolving a route

- ``ZRouteResolver``
- ``ZRouteModelResolver``
- ``ZTrieRouteResolver``
- ``ZEmptyModelResolver``
- ``ZResolvedScreen``
- ``ZRouteModels``

### Views

- ``ZNavigationStack``
- ``ZNavigationScope``
- ``ZRouteLink``
- ``ZRouteDestinationView``

### App level

- ``ZNavigationHub``
- ``ZPageViewReporter``

### Gating a route

- ``ZRouteGate``
- ``ZRouteGateDecision``

### Design and adoption

- <doc:UnifiedNavigationDesign>
- <doc:ZombieTronAdoption>
