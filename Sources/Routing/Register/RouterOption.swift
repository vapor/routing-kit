/// Available `TrieRouter` customization options.
public enum RouterOption {
    /// If set, this will cause the router's route matching to be case-insensitive.
    /// - note: Case-insensitive routing may be less performant than case-sensitive routing.
    case caseInsensitive
    
    /// If set, this the mount path will be prepended to all registered routes
    case mount([PathComponent])
}

extension RouterOption: Hashable {
    
    public var hashValue: Int {
        switch self {
        case .caseInsensitive:
            return 0
        case .mount(let path):
            return path.readable.hashValue
        }
    }
    
    public static func == (lhs: RouterOption, rhs: RouterOption) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
}
