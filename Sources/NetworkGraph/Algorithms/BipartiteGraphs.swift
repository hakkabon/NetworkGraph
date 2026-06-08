//
//  BipartiteGraphs.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/05/01.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public extension IncidenceGraph where Vertex: Hashable {
/*
    /// Determines the connected components in a graph.
    /// - Returns: True if graph is bipartite, false otherwise.
    func isBipartite() -> Bool {
        var bipatite = true
        var visited = Set<V>()
        var color: [V:Bool] = [:]

        func dfs(_ v: V) -> Bool {
            visited.insert(v)

            for u in adjacent(of: v) {
                if !visited.contains(u) {
                    color[u] = !color[v]!
                    if !dfs(u) { return false }
                } else if color[u] == color[v] {
                    return false
                }
            }
            return true
        }

        if let v = vertices.first {
            color[v] = true
            visited.insert(v)
            bipatite = dfs(v)
        }
        
        return bipatite
    }
*/
}
