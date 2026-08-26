//
//  RandomConnectedGraph.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Generates random connected graphs and Hamiltonian graphs (Topics 1.8, 1.9).
public enum RandomConnectedGraph {

    // MARK: - 1.8 Random Connected Graph

    /// Generates a random connected simple undirected graph on $V$ vertices with exactly $E$ edges.
    ///
    /// - Parameters:
    ///   - V: The number of vertices ($V \ge 1$).
    ///   - E: The number of edges ($V-1 \le E \le V(V-1)/2$).
    /// - Returns: A connected `AdjacentGraph<Int, NoProperty>`.
    public static func build(vertex V: Int, edge E: Int) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        let maxEdges = V * (V - 1) / 2
        guard E >= (V - 1) && E <= maxEdges else {
            throw NetworkGraphError.illegalArgument(cause: "Edge count E=\(E) must be between \(V-1) and \(maxEdges)")
        }

        // Start with a random spanning tree (1.5 / 1.6)
        var graph = try RandomTree.labeledTree(vertex: V)
        var existingEdges = Set<Edge>()
        for e in graph.edges {
            existingEdges.insert(Edge(u: Swift.min(e.u, e.v), v: Swift.max(e.u, e.v)))
        }

        // Collect all possible missing edges
        var missingEdges: [Edge] = []
        missingEdges.reserveCapacity(maxEdges - existingEdges.count)
        for u in 0..<V {
            for v in (u + 1)..<V {
                let e = Edge(u: u, v: v)
                if !existingEdges.contains(e) {
                    missingEdges.append(e)
                }
            }
        }

        RandomPermutation.shuffle(&missingEdges)
        let edgesToAdd = E - existingEdges.count
        for i in 0..<edgesToAdd {
            let e = missingEdges[i]
            _ = graph.addEdge(u: e.u, v: e.v)
        }

        return graph
    }

    // MARK: - 1.9 Random Hamilton Graph

    /// Generates a random undirected Hamiltonian graph on $V$ vertices with exactly $E$ edges.
    ///
    /// The graph is guaranteed to contain a Hamiltonian cycle.
    ///
    /// - Parameters:
    ///   - V: The number of vertices ($V \ge 3$).
    ///   - E: The number of edges ($V \le E \le V(V-1)/2$).
    /// - Returns: A Hamiltonian `AdjacentGraph<Int, NoProperty>`.
    public static func hamiltonGraph(vertex V: Int, edge E: Int) throws -> AdjacentGraph<Int, NoProperty> {
        guard V >= 3 else {
            throw NetworkGraphError.illegalArgument(cause: "Hamiltonian graphs require V >= 3")
        }
        let maxEdges = V * (V - 1) / 2
        guard E >= V && E <= maxEdges else {
            throw NetworkGraphError.illegalArgument(cause: "Edge count E=\(E) must be between \(V) and \(maxEdges)")
        }

        var graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: .undirected)
        let cycle = RandomPermutation.generate(n: V)

        var existingEdges = Set<Edge>()
        for i in 0..<V {
            let u = cycle[i]
            let v = cycle[(i + 1) % V]
            let norm = Edge(u: Swift.min(u, v), v: Swift.max(u, v))
            existingEdges.insert(norm)
            _ = graph.addEdge(u: u, v: v)
        }

        if E > V {
            var candidateChords: [Edge] = []
            for u in 0..<V {
                for v in (u + 1)..<V {
                    let norm = Edge(u: u, v: v)
                    if !existingEdges.contains(norm) {
                        candidateChords.append(norm)
                    }
                }
            }
            RandomPermutation.shuffle(&candidateChords)
            let additional = E - V
            for i in 0..<additional {
                let e = candidateChords[i]
                _ = graph.addEdge(u: e.u, v: e.v)
            }
        }

        return graph
    }
}
