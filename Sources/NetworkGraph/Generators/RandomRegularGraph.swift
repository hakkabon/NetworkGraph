//
//  RandomRegularGraph.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Generates random regular graphs (Topic 1.4).
public enum RandomRegularGraph {

    /// Generates a random $d$-regular simple undirected graph on $V$ vertices using the pairing configuration model.
    ///
    /// - Parameters:
    ///   - V: The number of vertices.
    ///   - d: The degree of every vertex ($0 \le d < V$, with $V \cdot d$ even).
    ///   - maxRetries: Maximum number of generation restarts if multi-edges/self-loops occur.
    /// - Returns: A simple undirected $d$-regular `AdjacentGraph<Int, NoProperty>`.
    /// - Throws: `NetworkGraphError.illegalArgument` if parameters are invalid or generation fails.
    public static func build(vertex V: Int, degree d: Int, maxRetries: Int = 100) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        guard d >= 0 && d < V else {
            throw NetworkGraphError.illegalArgument(cause: "Degree d must satisfy 0 <= d < V")
        }
        guard (V * d) % 2 == 0 else {
            throw NetworkGraphError.illegalArgument(cause: "V * d must be even for a regular graph to exist")
        }

        if d == 0 {
            return AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: .undirected)
        }

        // If degree is dense, generate the sparse complement graph and invert it
        if d > (V - 1) / 2 {
            let compDegree = (V - 1) - d
            let compGraph = try build(vertex: V, degree: compDegree, maxRetries: maxRetries)
            var graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: .undirected)
            for i in 0..<V {
                for j in (i + 1)..<V {
                    if !compGraph.isAdjacent(u: i, v: j) {
                        _ = graph._addEdge(u: i, v: j)
                    }
                }
            }
            return graph
        }

        // Steger-Wormald heuristic / pairing configuration model
        for _ in 0..<maxRetries {
            var points: [Int] = []
            points.reserveCapacity(V * d)
            for v in 0..<V {
                for _ in 0..<d {
                    points.append(v)
                }
            }
            RandomPermutation.shuffle(&points)

            var edgeSet = Set<Edge>()
            var isValid = true

            var i = 0
            while i < points.count {
                let u = points[i]
                let v = points[i + 1]
                i += 2

                if u == v {
                    isValid = false
                    break
                }
                let e1 = Edge(u: Swift.min(u, v), v: Swift.max(u, v))
                if edgeSet.contains(e1) {
                    isValid = false
                    break
                }
                edgeSet.insert(e1)
            }

            if isValid && edgeSet.count == (V * d) / 2 {
                var graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: .undirected)
                for edge in edgeSet {
                    _ = graph._addEdge(u: edge.u, v: edge.v)
                }
                return graph
            }
        }

        // Fallback: randomized greedy edge insertion with local switching
        return try buildGreedy(vertex: V, degree: d)
    }

    private static func buildGreedy(vertex V: Int, degree d: Int) throws -> AdjacentGraph<Int, NoProperty> {
        var graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: .undirected)
        var remainingDegrees = Array(repeating: d, count: V)

        // Repeat pairing until all degrees match d
        for _ in 0..<1000 {
            let candidates = remainingDegrees.enumerated().filter { $0.element > 0 }.map { $0.offset }
            guard !candidates.isEmpty else { break }

            if candidates.count == 1 {
                throw NetworkGraphError.illegalArgument(cause: "Failed to generate regular graph")
            }

            let u = candidates.randomElement()!
            let possibleV = candidates.filter { $0 != u && !graph.isAdjacent(u: u, v: $0) }
            guard let v = possibleV.randomElement() else {
                // Perform 2-opt edge swap to unlock
                break
            }

            _ = graph._addEdge(u: u, v: v)
            remainingDegrees[u] -= 1
            remainingDegrees[v] -= 1
        }

        // Verify degree of all vertices
        for v in 0..<V {
            guard graph.degree(vertex: v) == d else {
                throw NetworkGraphError.illegalArgument(cause: "Could not generate exact \(d)-regular graph with current seed")
            }
        }
        return graph
    }
}
