import RoutingKit
import XCTest


class ExtendableRouterTests: XCTestCase {
    func testBase() {
        let router = ExtendableRouter<String>()
        
        router.register("test", at: [ConstantComponent(value: "one"), ConstantComponent(value: "two")])
        router.register("test two", at: [ConstantComponent(value: "one"), ParameterComponent(parameterName: "three")])
        router.register("test three", at: [ConstantComponent(value: "two"), AnythingComponent(), ParameterComponent(parameterName: "three")])
        router.register("test four", at: [ConstantComponent(value: "one"), CustomRoutingComponent()])
        
        var context = RoutingContext(["one", "two"])
        XCTAssertEqual(router.route(context: &context), "test")
        
        context = RoutingContext(["one", "jfapoisdjfpaoisdjf"])
        let out = router.route(context: &context)
        XCTAssertEqual(out, "test two")
        
//        context = RoutingContext(["two", "jfapoisdjfpaoisdjf", "afpodsopf"])
        XCTAssertEqual(router.route(context: &context), "test three")
        
        context = RoutingContext(["one"])
        context.set(CustomRoutingKey.self, value: true)
        let result = router.route(context: &context)
        XCTAssertEqual(result, "test four")
    }
    
    func testCustomKey() {
        let router = ExtendableRouter<String>()
        
        let components: [RoutableComponent] = [ConstantComponent(value: "one"), CustomRoutingComponent()]
        
        router.register("test", at: components)
        
        var context = RoutingContext(["one"])
        context.set(CustomRoutingKey.self, value: true)
        XCTAssertEqual(router.route(context: &context), "test")
        
        context = RoutingContext(["two", "three"])
        
        XCTAssertNil(router.route(context: &context))
    }
}

struct CustomRoutingComponent: RoutableComponent {
    func check(_ context: RoutingContext) -> Bool {
        return context.get(CustomRoutingKey.self) ?? false
    }
    
    let identifier: String = "custom component"
}

struct CustomRoutingKey: RoutingContextKey {
    typealias Value = Bool
}
