import HTTP

extension Method {
    public static var wildcard: Method {
        return .other(method: "*")
    }
}
