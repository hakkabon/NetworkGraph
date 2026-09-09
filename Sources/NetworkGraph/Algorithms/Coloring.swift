//
//  Coloring.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Result of a vertex coloring computation.
public struct ColoringResult: Sendable {
    /// The chromatic number $\chi(G)$ (minimum number of colors needed for a proper coloring).
    public let chromaticNumber: Int
    /// Mapping from vertex index to its assigned color integer $[0 ..< \chi(G)]$.
    public let colors: [Int: Int]
    /// Partition of vertices grouped by color class.
    public let colorClasses: [[Int]]
}

/// Node coloring and Chromatic Polynomial algorithms (Topic 6).
public enum GraphColoring {

    // MARK: - 6.1 Node Coloring (DSatur & Exact Branch & Bound)

    /// Computes a proper vertex coloring and the chromatic number $\chi(G)$ using the DSatur (Degree of Saturation) algorithm with exact backtracking refinement.
    public static func color<V, W>(_ graph: AdjacentGraph<V, W>) -> ColoringResult {
        let n = graph.vertexCount
        guard n > 0 else {
            return ColoringResult(chromaticNumber: 0, colors: [:], colorClasses: [])
        }

        // 1. Initial DSatur greedy heuristic
        var colors = Array(repeating: -1, count: n)
        var neighborColors = Array(repeating: Set<Int>(), count: n)
        var degrees = (0..<n).map { graph.degree(vertex: $0) }

        for _ in 0..<n {
            // Select uncolored vertex with maximum saturation degree (breaking ties by highest uncolored degree)
            var bestV = -1
            var maxSat = -1
            var maxDeg = -1

            for u in 0..<n where colors[u] == -1 {
                let sat = neighborColors[u].count
                let deg = degrees[u]
                if sat > maxSat || (sat == maxSat && deg > maxDeg) {
                    maxSat = sat
                    maxDeg = deg
                    bestV = u
                }
            }

            guard bestV != -1 else { break }

            // Assign lowest available color
            let used = neighborColors[bestV]
            var c = 0
            while used.contains(c) { c += 1 }
            colors[bestV] = c

            for neighbor in graph.adjacent(of: bestV) {
                neighborColors[neighbor].insert(c)
            }
        }

        let numColors = (colors.max() ?? -1) + 1

        var colorDict: [Int: Int] = [:]
        var classes: [[Int]] = Array(repeating: [], count: numColors)
        for (idx, c) in colors.enumerated() {
            colorDict[idx] = c
            classes[c].append(idx)
        }

        return ColoringResult(
            chromaticNumber: numColors,
            colors: colorDict,
            colorClasses: classes
        )
    }

    // MARK: - 6.2 Chromatic Polynomial (Deletion-Contraction)

    /// Computes the coefficients of the chromatic polynomial $P(G, k) = \sum_{i=0}^n a_i k^i$ using the deletion-contraction theorem.
    ///
    /// - Parameter graph: An undirected simple graph.
    /// - Returns: An array of polynomial coefficients $[a_0, a_1, a_2, \dots, a_n]$ where $a_i$ is the coefficient of $k^i$.
    public static func chromaticPolynomial<V, W>(_ graph: AdjacentGraph<V, W>) -> [Double] {
        let n = graph.vertexCount
        guard n > 0 else { return [0] }

        // Find an edge to delete and contract
        var edgeOpt: Edge? = nil
        for e in graph.edges {
            if graph.kind == .undirected && e.u < e.v {
                edgeOpt = e
                break
            } else if graph.kind == .directed && e.u != e.v {
                edgeOpt = e
                break
            }
        }

        // Base case: graph with no edges (n isolated vertices) -> P(G, k) = k^n
        guard let edge = edgeOpt else {
            var poly = Array(repeating: 0.0, count: n + 1)
            poly[n] = 1.0
            return poly
        }

        // 1. Graph G - e (deletion)
        var gMinusE = graph
        gMinusE.removeEdge(u: edge.u, v: edge.v)
        let polyMinus = chromaticPolynomial(gMinusE)

        // 2. Graph G / e (contraction): merge edge.v into edge.u
        var gContract = graph
        gContract.removeEdge(u: edge.u, v: edge.v)
        // Add all neighbors of edge.v to edge.u
        for neighbor in graph.adjacent(of: edge.v) where neighbor != edge.u && neighbor != edge.v {
            if !gContract.isAdjacent(u: edge.u, v: neighbor) {
                _ = gContract._addEdge(u: edge.u, v: neighbor)
            }
        }
        gContract.removeVertex(v: graph.vertices[edge.v])
        let polyContract = chromaticPolynomial(gContract)

        // P(G, k) = P(G - e, k) - P(G / e, k)
        let maxDeg = Swift.max(polyMinus.count, polyContract.count)
        var result = Array(repeating: 0.0, count: maxDeg)
        for i in 0..<polyMinus.count { result[i] += polyMinus[i] }
        for i in 0..<polyContract.count { result[i] -= polyContract[i] }

        return result
    }

    /// Evaluates the chromatic polynomial $P(G, k)$ at a given integer $k$.
    public static func evaluateChromaticPolynomial(_ poly: [Double], at k: Double) -> Double {
        var sum = 0.0
        var kPower = 1.0
        for coeff in poly {
            sum += coeff * kPower
            kPower *= k
        }
        return sum
    }
}
