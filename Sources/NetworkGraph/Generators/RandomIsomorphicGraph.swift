//
//  RandomIsomorphicGraph.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Pair of isomorphic graphs along with the bijective permutation mapping between them.
public struct IsomorphicPair<V: Hashable & Codable, W: Hashable & Codable> {
    /// The base graph $G$.
    public let original: AdjacentGraph<V, W>
    /// The permuted isomorphic graph $G^\pi$.
    public let permuted: AdjacentGraph<V, W>
    /// The vertex bijection $\pi: V(G) \to V(G^\pi)$ where vertex $i$ in $G$ maps to $\pi[i]$ in $G^\pi$.
    public let mapping: [Int]
    /// The inverse vertex bijection $\pi^{-1}: V(G^\pi) \to V(G)$.
    public let inverseMapping: [Int]
}

/// Generates pairs of random isomorphic graphs (Topics 1.11, 1.12).
public enum RandomIsomorphicGraph {

    // MARK: - 1.11 Random Isomorphic Graphs

    /// Applies a random permutation $\pi$ to a graph $G$ to produce an isomorphic graph $G^\pi$.
    ///
    /// - Parameter graph: The source graph.
    /// - Returns: An `IsomorphicPair` containing $(G, G^\pi, \pi, \pi^{-1})$.
    public static func permute<V, W>(_ graph: AdjacentGraph<V, W>) -> IsomorphicPair<V, W> {
        let V_count = graph.vertexCount
        let pi = RandomPermutation.generate(n: V_count)
        var inv = Array(repeating: 0, count: V_count)
        for i in 0..<V_count {
            inv[pi[i]] = i
        }

        // Reconstruct vertices in permuted order
        var permutedVertices = Array(repeating: graph.vertices[0], count: V_count)
        for i in 0..<V_count {
            permutedVertices[pi[i]] = graph.vertices[i]
        }

        var permutedGraph = AdjacentGraph<V, W>(vertices: permutedVertices, kind: graph.kind)

        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let u_perm = pi[edge.u]
            let v_perm = pi[edge.v]
            _ = permutedGraph.addEdge(u: u_perm, v: v_perm)
            if let prop = graph.edgeProperties[edge] {
                permutedGraph[Edge(u: u_perm, v: v_perm)] = prop
                if graph.kind == .undirected && u_perm != v_perm {
                    permutedGraph[Edge(u: v_perm, v: u_perm)] = prop
                }
            }
        }

        return IsomorphicPair(
            original: graph,
            permuted: permutedGraph,
            mapping: pi,
            inverseMapping: inv
        )
    }

    /// Generates a random graph $G(V, E)$ and returns an isomorphic pair $(G, G^\pi)$.
    public static func build(vertex V: Int, edge E: Int) throws -> IsomorphicPair<Int, NoProperty> {
        let base = try RandomConnectedGraph.build(vertex: V, edge: E)
        return permute(base)
    }

    // MARK: - 1.12 Random Isomorphic Regular Graphs

    /// Generates a random $d$-regular graph on $V$ vertices and returns an isomorphic pair $(G, G^\pi)$.
    public static func regular(vertex V: Int, degree d: Int) throws -> IsomorphicPair<Int, NoProperty> {
        let base = try RandomRegularGraph.build(vertex: V, degree: d)
        return permute(base)
    }
}
