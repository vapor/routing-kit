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
    private var hasOutput: Bool { return output != nil }
    internal var branchesWithOutput: [Branch] {
        var outputs = [Branch]()
        if hasOutput {
            outputs.append(self)
        }

        return outputs
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
