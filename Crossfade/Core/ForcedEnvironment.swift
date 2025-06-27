import SwiftUI

@propertyWrapper
public struct ForcedEnvironment<Value>: DynamicProperty {
    @Environment private var env: Value?
    
    public init(_ keyPath: KeyPath<EnvironmentValues, Value?>) {
        _env = Environment(keyPath)
    }
    
    public var wrappedValue: Value {
        if let env {
            return env
        } else {
            fatalError("\(Value.self) not provided")
        }
    }
}