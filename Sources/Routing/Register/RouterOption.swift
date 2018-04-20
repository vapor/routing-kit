/// Available `TrieRouter` customization options.
public enum RouterOption {
    /// If set, this will cause the router's route matching to be case-insensitive.
    /// - note: Case-insensitive routing may be less performant than case-sensitive routing.
    case caseInsensitive
}
