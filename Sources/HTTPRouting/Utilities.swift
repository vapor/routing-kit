extension String {
    /**
        Separates a URI path into
        an array by splitting on `/`
    */
    var pathComponents: [String] {
        return characters
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0) }
    }
}

extension Sequence where Iterator.Element == String {
    var pathComponents: [String] {
        return flatMap { $0.pathComponents }
    }
}
