struct SubBranchMap<Output> {
    var paramBranches: [String: Branch<Output>] = [:]
    var slugBranches: [Branch<Output>] = []
    var wildcard: Branch<Output>?

    var allBranches: [Branch<Output>] {
        var all = [Branch<Output>]()
        all += paramBranches.values
        all += slugBranches
        if let wildcard = wildcard {
            all.append(wildcard)
        }
        return all
    }

    init() {}

    subscript(key: String) -> Branch<Output>? {
        get {
            if key == "*" {
                return wildcard
            } else if key.hasPrefix(":") {
                return slugBranches.lazy.filter { $0.name == key } .first
            } else {
                return paramBranches[key]
            }
        }
        set {
            if key == "*" {
                wildcard = newValue
            } else if key.hasPrefix(":") {
                if let existing = slugBranches.index(where: { $0.name == key }) {
                    if let value = newValue {
                        slugBranches[existing] = value
                    } else {
                        slugBranches.remove(at: existing)
                    }
                } else if let value = newValue {
                    slugBranches.append(value)
                }
            } else {
                paramBranches[key] = newValue
            }
        }
    }
}
