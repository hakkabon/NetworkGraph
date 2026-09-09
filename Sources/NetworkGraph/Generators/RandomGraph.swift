//
//  RandomGraph.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public enum RandomGraph {

    /// Returns a random graph containing `V` vertices and `E` edges.
    ///
    /// - Parameters:
    ///   - V: the number of vertices
    ///   - E: the number of edges
    ///   - kind: directed or undirected (default directed)
    /// - Returns: a random simple graph on V vertices, containing a total of E edges
    /// - Throws: IllegalArgument if no such simple graph exists
    public static func build(vertex V: Int, edge E: Int, kind: GraphType = .directed) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        let maxEdges = kind == .directed ? V * (V - 1) : V * (V - 1) / 2
        guard E <= maxEdges else {
            throw NetworkGraphError.illegalArgument(cause: "Too many edges (max \(maxEdges))")
        }
        guard E >= 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Too few edges")
        }

        var allPossibleEdges: [Edge] = []
        allPossibleEdges.reserveCapacity(maxEdges)
        if kind == .directed {
            for u in 0..<V {
                for v in 0..<V where u != v {
                    allPossibleEdges.append(Edge(u: u, v: v))
                }
            }
        } else {
            for u in 0..<V {
                for v in (u + 1)..<V {
                    allPossibleEdges.append(Edge(u: u, v: v))
                }
            }
        }

        RandomPermutation.shuffle(&allPossibleEdges)

        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: kind)
        for i in 0..<E {
            let e = allPossibleEdges[i]
            _ = g._addEdge(u: e.u, v: e.v)
        }
        return g
    }
    
    /// Returns an Erdos Renyi random graph containing `V` vertices with edge probability `p`.
    ///
    /// - Parameters:
    ///   - V: the number of vertices
    ///   - p: the probability that any given edge exists
    ///   - kind: directed or undirected
    /// - Returns: a random simple graph on `V` vertices
    public static func build(vertex V: Int, probability p: Float, kind: GraphType = .directed) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        guard p >= 0.0 && p <= 1.0 else {
            throw NetworkGraphError.illegalArgument(cause: "Probability must be in [0, 1]")
        }

        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: kind)
        if kind == .directed {
            for u in 0..<V {
                for v in 0..<V where u != v {
                    if Float.random(in: 0...1) < p {
                        _ = g._addEdge(u: u, v: v)
                    }
                }
            }
        } else {
            for u in 0..<V {
                for v in (u + 1)..<V {
                    if Float.random(in: 0...1) < p {
                        _ = g._addEdge(u: u, v: v)
                    }
                }
            }
        }
        return g
    }
}

public enum BipartiteRandomGraph {

    /// Returns a bipartite random graph containing partition sets `V1` and `V2` with `E` edges.
    ///
    /// - Parameters:
    ///   - V1: the number of vertices in partition 1 [0 ..< V1]
    ///   - V2: the number of vertices in partition 2 [V1 ..< V1 + V2]
    ///   - edge: total edges
    ///   - kind: directed or undirected (default directed)
    /// - Returns: a random bipartite simple graph on `V1 + V2` vertices
    public static func build(partition V1: Int, partition V2: Int, edge E: Int, kind: GraphType = .directed) throws -> AdjacentGraph<Int, NoProperty> {
        guard V1 > 0 && V2 > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Partitions must be non-empty")
        }
        let maxEdges = V1 * V2
        guard E <= maxEdges else {
            throw NetworkGraphError.illegalArgument(cause: "Too many edges (max \(maxEdges))")
        }
        guard E >= 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Too few edges")
        }

        var allPossibleEdges: [Edge] = []
        allPossibleEdges.reserveCapacity(maxEdges)
        for i in 0..<V1 {
            for j in 0..<V2 {
                allPossibleEdges.append(Edge(u: i, v: V1 + j))
            }
        }

        RandomPermutation.shuffle(&allPossibleEdges)

        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<(V1 + V2)), kind: kind)
        for k in 0..<E {
            let e = allPossibleEdges[k]
            _ = g._addEdge(u: e.u, v: e.v)
        }
        return g
    }

    /// Returns a bipartite random graph containing `V1` and `V2` vertices with edge probability `p`.
    public static func build(firstPartitionVertex V1: Int, vertex V2: Int, probability p: Float, kind: GraphType = .directed) throws -> AdjacentGraph<Int, NoProperty> {
        guard V1 > 0 && V2 > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Partitions must be non-empty")
        }
        guard p >= 0.0 && p <= 1.0 else {
            throw NetworkGraphError.illegalArgument(cause: "Probability must be in [0, 1]")
        }

        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<(V1 + V2)), kind: kind)
        for i in 0..<V1 {
            for j in 0..<V2 {
                if Float.random(in: 0...1) < p {
                    _ = g._addEdge(u: i, v: V1 + j)
                }
            }
        }
        return g
    }
}
