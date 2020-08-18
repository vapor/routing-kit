public struct RoutingContext {
    var storage: [ObjectIdentifier: AnyRoutingContextValue]
    fileprivate(set) var path: [String]
    
    public init(_ path: [String]) {
        self.storage = [:]
        self.path = path.reversed()
    }
    
    struct Value<T>: AnyRoutingContextValue {
        var value: T
    }
    
    internal mutating func popPathComponent() -> String? {
        return self.path.popLast()
    }
    
    public mutating func set<Key>(_ key: Key.Type, value: Key.Value?) where Key: RoutingContextKey {
        if let value = value {
            self.storage[key.key] = Value(value: value)
        } else {
            self.storage[key.key] = nil
        }
    }
    
    public func get<Key>(_ key: Key.Type) -> Key.Value? where Key: RoutingContextKey {
        guard let value = self.storage[key.key] as? Value<Key.Value> else {
            return nil
        }
        return value.value
    }
}

protocol AnyRoutingContextValue { }

public enum RoutingKey { }

public protocol RoutingContextKey {
    associatedtype Value
}

extension RoutingContextKey {
    static var key: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

public protocol RoutableComponent {
    func check(_ context: RoutingContext) -> Bool
    
    var identifier: String { get }
}

extension RoutableComponent {
    static func constant(_ string: String) -> RoutableComponent {
        return ConstantComponent(value: string)
    }
    
    static func parameter(_ string: String) -> RoutableComponent {
        return ParameterComponent(parameterName: string)
    }
    
    static var catchall: RoutableComponent {
        return CatchallComponent()
    }
    
    static var anything: RoutableComponent {
        return AnythingComponent()
    }
}

public struct ConstantComponent: RoutableComponent {
    let value: String
    
    public var identifier: String {
        self.value
    }
    
    public init(value: String) {
        self.value = value
    }
    
    public func check(_ context: RoutingContext) -> Bool {
        return false
//        return self.value == context.nextPathComponent()
    }
}

public struct ParameterComponent: RoutableComponent {
    let parameterName: String
    
    public var identifier: String {
        self.parameterName
    }
    
    public init(parameterName: String) {
        self.parameterName = parameterName
    }
    
    public func check(_ context: RoutingContext) -> Bool {
        return false
//        guard let _ = context.nextPathComponent() else { return false }
//        return true
    }
    
    public func check(_ pathComponent: String?) -> Bool {
        return pathComponent != nil
    }
}

public struct CatchallComponent: RoutableComponent {
    public let identifier: String = "catchall"
    
    public func check(_ context: RoutingContext) -> Bool {
        return true
    }
}


public struct AnythingComponent: RoutableComponent {
    public let identifier: String = "anything"
    
    public init() {}
    
    public func check(_ context: RoutingContext) -> Bool {
        return false
//        guard let _ = context.nextPathComponent() else { return false }
//        return true
    }
    
    public func check(_ pathComponent: String?) -> Bool {
        return pathComponent != nil
    }
}
