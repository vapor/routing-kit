# ``RoutingKit``

RoutingKit is a high-performance, trie-node router to route HTTP requests to the correct route handler. It allows for dynamic path parameters to make building web frameworks easy.

### Installation

Manually add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/vapor/routing-kit.git", from: "5.0.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "RoutingKit", package: "routing-kit"),
        ]
    ),
]
```

### Usage

To use RoutingKit, first import the module:

```swift
import RoutingKit
```

Then, create a router builder instance:

```swift
let builder = TrieRouterBuilder(String.self)
// or
let builder = TrieRouterBuilder<Int>()
```

Next, register routes with associated handlers:

```swift
builder.register("handler1", at: ["users", ":id"])
builder.register("handler2", at: ["posts", ":postId", "comments"])
```

Finally, build the router and use it to route incoming paths:

```swift
let router = builder.build()
var params = Parameters()
if let handler = router.route(["users", "123"], parameters: &params) {
    print("Routed to handler: \(handler) with params: \(params)")
}
```

> Note: To preserve both speed and safety, once you create a router using the `build()` method, it becomes immutable. Any further modifications require creating a new builder instance.

There's different types of path components you can use when registering routes:
- Constant path components: e.g. `"users"`, `"posts"`
- Parameter path components: e.g. `":id"`, `":postId"`
- Wildcard path components: e.g. `"*"`
- Partial parameter path components: e.g. `":{file-name}.{ext}"`

All of these can be used simply by passing the appropriate strings to the `register` method.

#### Custom Router

You can also create your own custom router by conforming to the ``Router`` protocol. This allows you to define your own routing logic rather than using the built-in trie-based router.
