public enum TypeSafeRoutingError: Error {
    case missingParameter
    case invalidParameterType(Any.Type)
}
