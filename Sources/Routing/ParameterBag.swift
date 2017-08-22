/// A bag for holding parameters resolved during router
public struct ParameterBag {
    /// The parameters
    public var parameters: [Parameter]

    /// Create a new parameters bag
    public init() {
        self.parameters = []
    }
}
