//
//  Router+Routes.swift
//  Routing
//
//  Created by Logan Wright on 11/1/16.
//
//

import Foundation

extension Router {
    public var routes: [String] {
        var routes = [String]()
        tree.forEach { host, methodTree in
            methodTree.forEach { method, branch in
                let base = "\(host) \(method) "
                routes += branch.routes.map { base + $0 }
            }
        }
        return routes
    }
}

extension Branch {
    public var routes: [String] {
        return allBranchesWithOutputIncludingSelf.map { $0.route }
    }
}

extension Branch {
    internal var allBranchesWithOutputIncludingSelf: [Branch] {
        return allIndividualBranchesInTreeIncludingSelf.filter { $0.output != nil }
    }
}

extension Branch {
    // Get all individual branch nodes extending out from, and including self
    internal var allIndividualBranchesInTreeIncludingSelf: [Branch] {
        var branches: [Branch] = [self]
        branches += subBranches.allBranches.flatMap { $0.allIndividualBranchesInTreeIncludingSelf }
        return branches
    }
}

extension Branch {
    // The individual route leading to the calling branch
    internal var route: String {
        var route = ""
        if !name.isEmpty {
            route += "/\(name)"
        }
        if let parent = parent {
            route = parent.route + route
        }
        return route
    }
}
