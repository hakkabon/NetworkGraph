//
//  RandomTree.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Generates random spanning trees, labeled trees, and unlabeled rooted trees (Topics 1.5, 1.6, 1.7).
public enum RandomTree {

    // MARK: - 1.5 Random Spanning Tree (Wilson's Algorithm)

    /// Generates a uniform random spanning tree of an arbitrary connected graph using Wilson's loop-erased random walk algorithm.
    ///
    /// - Parameter graph: A connected `AdjacentGraph`.
    /// - Returns: An `AdjacentGraph` containing the exact tree edges on the same vertices.
    public static func spanningTree<V, W>(of graph: AdjacentGraph<V, W>) throws -> AdjacentGraph<V, NoProperty> {
        let V_count = graph.vertexCount
        guard V_count > 0 else {
            return AdjacentGraph<V, NoProperty>(vertices: [], kind: graph.kind)
        }
        if V_count == 1 {
            return AdjacentGraph<V, NoProperty>(vertices: graph.vertices, kind: graph.kind)
        }

        var tree = AdjacentGraph<V, NoProperty>(vertices: graph.vertices, kind: graph.kind)
        var inTree = Array(repeating: false, count: V_count)
        inTree[0] = true
        var next = Array(repeating: -1, count: V_count)

        for i in 1..<V_count {
            var u = i
            while !inTree[u] {
                let neighbors = graph.adjacent(of: u)
                guard !neighbors.isEmpty else {
                    throw NetworkGraphError.illegalArgument(cause: "Graph is not connected")
                }
                let step = neighbors.randomElement()!
                next[u] = step
                u = step
            }

            u = i
            while !inTree[u] {
                inTree[u] = true
                let v = next[u]
                _ = tree._addEdge(u: u, v: v)
                u = v
            }
        }
        return tree
    }

    /// Generates a uniform random spanning tree on $V$ labeled vertices (spanning tree of $K_V$).
    public static func uniformSpanningTree(vertex V: Int) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        if V == 1 {
            return AdjacentGraph<Int, NoProperty>(vertices: [0], kind: .undirected)
        }
        // Prüfer sequence of length V - 2
        return try labeledTree(vertex: V)
    }

    // MARK: - 1.6 Random Labeled Tree (Prüfer Sequence)

    /// Generates a uniform random labeled tree on $V$ vertices via a random Prüfer sequence ($n^{n-2}$ Cayley distribution).
    ///
    /// - Parameter V: The number of vertices ($V \ge 1$).
    /// - Returns: An undirected tree `AdjacentGraph<Int, NoProperty>`.
    public static func labeledTree(vertex V: Int) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        if V == 1 {
            return AdjacentGraph<Int, NoProperty>(vertices: [0], kind: .undirected)
        }
        if V == 2 {
            var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1], kind: .undirected)
            _ = g._addEdge(u: 0, v: 1)
            return g
        }

        // Generate random Prüfer sequence of length V - 2 with values in 0..<V
        var sequence = [Int]()
        sequence.reserveCapacity(V - 2)
        for _ in 0..<(V - 2) {
            sequence.append(Int.random(in: 0..<V))
        }

        return fromPruferSequence(sequence, vertexCount: V)
    }

    /// Reconstructs a labeled tree from a Prüfer sequence in $O(V)$ time.
    public static func fromPruferSequence(_ sequence: [Int], vertexCount: Int) -> AdjacentGraph<Int, NoProperty> {
        var degree = Array(repeating: 1, count: vertexCount)
        for node in sequence {
            degree[node] += 1
        }

        var tree = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<vertexCount), kind: .undirected)

        // Find initial leaf with smallest label
        var leafIndex = 0
        while leafIndex < vertexCount && degree[leafIndex] != 1 {
            leafIndex += 1
        }

        var ptr = leafIndex
        for node in sequence {
            _ = tree._addEdge(u: leafIndex, v: node)
            degree[leafIndex] -= 1
            degree[node] -= 1

            if degree[node] == 1 && node < ptr {
                leafIndex = node
            } else {
                ptr += 1
                while ptr < vertexCount && degree[ptr] != 1 {
                    ptr += 1
                }
                leafIndex = ptr
            }
        }

        // Connect the last two remaining vertices with degree == 1
        var u = -1
        var v = -1
        for i in 0..<vertexCount {
            if degree[i] == 1 {
                if u == -1 { u = i } else { v = i; break }
            }
        }
        if u != -1 && v != -1 {
            _ = tree._addEdge(u: u, v: v)
        }

        return tree
    }

    // MARK: - 1.7 Random Unlabeled Rooted Tree

    /// Generates a random unlabeled rooted tree on $V$ vertices using recursive subtree partitioning.
    ///
    /// - Parameter V: The number of vertices ($V \ge 1$).
    /// - Parameter root: The root vertex index (defaults to 0).
    /// - Returns: A directed tree `AdjacentGraph<Int, NoProperty>` with edges directed from parent to child.
    public static func unlabeledRootedTree(vertex V: Int, root: Int = 0) throws -> AdjacentGraph<Int, NoProperty> {
        guard V > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Vertex count must be positive")
        }
        var tree = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<V), kind: .directed)
        guard V > 1 else { return tree }

        // Recursive tree generation: assign random parent in existing connected set
        for v in 1..<V {
            let parent = Int.random(in: 0..<v)
            _ = tree._addEdge(u: parent, v: v)
        }
        return tree
    }
}
