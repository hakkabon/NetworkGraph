//
//  NamedGraph.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// A type used to construct an UnweightedGraph with vertices of type V that is isomorphic to a star graph.
/// https://en.wikipedia.org/wiki/Star_(graph_theory)
public enum StarGraph<V: Hashable & Codable> {

    /// Constructs an undirected UnweightedGraph isomorphic to a star graph.
    ///
    /// - Parameters:
    ///   - center: The vertex that is connected to all vertices except itself.
    ///   - leafs: The set of vertices that are connected only to the center vertex.
    /// - Returns: An UnweightedGraph star graph with the center vertex connected to all the leafs. The leafs
    ///            are only connected to the center
    public static func build(withCenter center: V, andLeafs leafs: [V]) -> AdjacentGraph<V,NoProperty> {
        var g = AdjacentGraph<V,NoProperty>(vertices: [center] + leafs)

        guard leafs.count > 0 else { return g }
        for i in 1...leafs.count {
            _ = g.addEdge(u: 0, v: i)
        }
        return g
    }
}

/// A type used to construct UnweightedGraph with vertices of type V that is isomorphic to a complete graph.
/// Complete graph <=> Fully connected graph.
/// https://en.wikipedia.org/wiki/Complete_graph
public enum CompleteGraph<V: Hashable & Codable> {

    /// Constructs an undirected UnweightedGraph isomorphic to a complete graph.
    /// Number of eges (n(n - 1)) / 2.
    /// - Parameter vertices: The set of vertices of the graph.
    /// - Returns: An UnweightedGraph complete graph, a graph with each vertex connected to all the vertices except itself.
    public static func build(vertices vs: [V]) -> AdjacentGraph<V,NoProperty> {
        var g = AdjacentGraph<V,NoProperty>(vertices: vs)

        for u in 0..<vs.count {
            for v in 0..<u {
                _ = g.addEdge(u: u, v: v)
            }
        }
        return g
    }
}

public enum PathGraph<V: Hashable & Codable> {

    /// Initialize an UnweightedGraph consisting of path.
    ///
    /// The resulting graph has the vertices in path and an edge between
    /// each pair of consecutive vertices in path.
    ///
    /// If path is an empty array, the resulting graph is the empty graph.
    /// If path is an array with a single vertex, the resulting graph has that vertex and no edges.
    ///
    /// - Parameters:
    ///   - path: An array of vertices representing a path.
    ///   - directed: If false, undirected edges are created.
    ///               If true, edges are directed from vertex i to vertex i+1 in path.
    public static func withPath(_ path: [V], directed: Bool = false) -> AdjacentGraph<V,NoProperty> {
        var g = AdjacentGraph<V,NoProperty>(vertices: path)
        
        guard path.count >= 2 else {
            return g
        }

        for i in 0 ... path.count-2 {
            _ = g.addEdge(u: i, v: i+1)
        }

        return g
    }
}

public enum CycleGraph<V: Hashable & Codable> {

    /// Initialize an UnweightedGraph consisting of cycle.
    ///
    /// The resulting graph has the vertices in cycle and an edge between
    /// each pair of consecutive vertices in cycle,
    /// plus an edge between the last and the first vertices.
    ///
    /// If path is an empty array, the resulting graph is the empty graph.
    /// If path is an array with a single vertex, the resulting graph has that vertex and no edges.
    ///
    /// - Parameters:
    ///   - cycle: An array of vertices representing a cycle.
    ///   - directed: If false, undirected edges are created.
    ///               If true, edges are directed from vertex i to vertex i+1 in cycle.
    public static func withCycle(_ cycle: [V], directed: Bool = false) -> AdjacentGraph<V,NoProperty> {
        var g = AdjacentGraph<V,NoProperty>(vertices: cycle)

        guard cycle.count >= 2 else {
            return g
        }

        for i in 0 ... cycle.count-2 {
            _ = g.addEdge(u: i, v: i+1)
        }
        _ = g.addEdge(u: cycle.count-1, v: 0)
        
        return g
    }
}
