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
        
        return []
    }

    public func logRoutes(logger: (String) -> Void) {

    }
}

func gatherRoutes<T>(_ dict: [Method: Branch<T>]) {

}

extension Branch {
    public var routes: [String] {
        var routes = [String]()
        var base = "/\(name)/"


        return routes
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
        branches += subBranches.values.flatMap { $0.allIndividualBranchesInTreeIncludingSelf }
        return branches
    }
}

extension Branch {
    // The individual route leading to the calling branch
    internal var route: String {
        var route = "/\(name)"
        if let parent = parent {
            route = parent.route + route
        }
        return route
    }
}
