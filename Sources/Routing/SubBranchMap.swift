extension Branch {
    struct SubBranchMap {
        var paramBranches: [String: Branch] = [:]
        var slugBranches: [Branch] = []
        var wildcard: Branch?

        var allBranches: [Branch] {
            var all = [Branch]()
            all += paramBranches.values
            all += slugBranches
            if let wildcard = wildcard {
                all.append(wildcard)
            }
            return all
        }

        init() {}

        subscript(key: String) -> Branch? {
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
}
