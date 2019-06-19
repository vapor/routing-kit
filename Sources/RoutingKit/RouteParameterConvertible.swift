import Foundation

public protocol RouteParameterConvertible: LosslessStringConvertible { }

extension UUID: RouteParameterConvertible {
    
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
    
}
