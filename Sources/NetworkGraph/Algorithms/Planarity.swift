//
//  Planarity.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Result of a planarity test.
public struct PlanarityResult: Sendable {
    /// `true` if the graph is planar (can be drawn on the plane with no intersecting edges).
    public let isPlanar: Bool
    /// If non-planar, optional Kuratowski minor ($K_5$ or $K_{3,3}$) or obstructing edge subset.
    public let obstructingEdges: [Edge]?
}

/// Planarity testing algorithms (Topic 4).
public enum Planarity {

    /// Tests if an undirected graph is planar using the Hopcroft-Tarjan linear-time framework ($O(V+E)$).
    ///
    /// - Parameter graph: An undirected graph.
    /// - Returns: A `PlanarityResult` indicating whether the graph is planar.
    public static func isPlanar<V, W>(_ graph: AdjacentGraph<V, W>) -> PlanarityResult {
        let n = graph.vertexCount
        // Disconnected graphs: planar iff every connected component is planar
        let comps = Connectivity.connectedComponents(graph)
        if comps.count > 1 {
            for comp in comps {
                var subg = AdjacentGraph<Int, NoProperty>(vertices: comp, kind: .undirected)
                let compSet = Set(comp)
                for edge in graph.edges {
                    if graph.kind == .undirected && edge.u > edge.v { continue }
                    if compSet.contains(edge.u) && compSet.contains(edge.v) {
                        let uSub = comp.firstIndex(of: edge.u)!
                        let vSub = comp.firstIndex(of: edge.v)!
                        _ = subg._addEdge(u: uSub, v: vSub)
                    }
                }
                let res = isPlanarComponent(subg)
                if !res.isPlanar { return res }
            }
            return PlanarityResult(isPlanar: true, obstructingEdges: nil)
        }

        return isPlanarComponent(graph)
    }

    private static func isPlanarComponent<V, W>(_ graph: AdjacentGraph<V, W>) -> PlanarityResult {
        let n = graph.vertexCount
        if n <= 4 { return PlanarityResult(isPlanar: true, obstructingEdges: nil) }

        // Count distinct undirected edges
        var distinctEdgeCount = 0
        for edge in graph.edges {
            if graph.kind == .undirected && edge.u < edge.v {
                distinctEdgeCount += 1
            } else if graph.kind == .directed {
                distinctEdgeCount += 1
            }
        }

        // Euler's formula invariant: for any simple planar graph with V >= 3, E <= 3V - 6
        if distinctEdgeCount > 3 * n - 6 {
            return PlanarityResult(isPlanar: false, obstructingEdges: nil)
        }

        // Hopcroft-Tarjan path addition testing:
        // 1. Compute DFS tree and discovery / lowpt values
        var disc = Array(repeating: -1, count: n)
        var lowpt1 = Array(repeating: -1, count: n)
        var lowpt2 = Array(repeating: -1, count: n)
        var parent = Array(repeating: -1, count: n)
        var dfsOrder: [Int] = []
        var timer = 0

        func dfs(_ u: Int, _ p: Int) {
            timer += 1
            disc[u] = timer
            lowpt1[u] = disc[u]
            lowpt2[u] = disc[u]
            parent[u] = p
            dfsOrder.append(u)

            for v in graph.adjacent(of: u) {
                if v == p { continue }
                if disc[v] != -1 {
                    // Back-edge
                    if disc[v] < lowpt1[u] {
                        lowpt2[u] = lowpt1[u]
                        lowpt1[u] = disc[v]
                    } else if disc[v] > lowpt1[u] && disc[v] < lowpt2[u] {
                        lowpt2[u] = disc[v]
                    }
                } else {
                    // Tree edge
                    dfs(v, u)
                    if lowpt1[v] < lowpt1[u] {
                        lowpt2[u] = Swift.min(lowpt1[u], lowpt2[v])
                        lowpt1[u] = lowpt1[v]
                    } else if lowpt1[v] == lowpt1[u] {
                        lowpt2[u] = Swift.min(lowpt2[u], lowpt2[v])
                    } else if lowpt1[v] < lowpt2[u] {
                        lowpt2[u] = lowpt1[v]
                    }
                }
            }
        }

        for i in 0..<n {
            if disc[i] == -1 {
                dfs(i, -1)
            }
        }

        // 2. Check Kuratowski minor subgraph embedding conflicts
        let isPlanar = testEmbedding(graph: graph, disc: disc, lowpt1: lowpt1, lowpt2: lowpt2, parent: parent)
        return PlanarityResult(isPlanar: isPlanar, obstructingEdges: nil)
    }

    private static func testEmbedding<V, W>(
        graph: AdjacentGraph<V, W>,
        disc: [Int],
        lowpt1: [Int],
        lowpt2: [Int],
        parent: [Int]
    ) -> Bool {
        let n = graph.vertexCount
        var cycles: [[Int]] = []

        // Extract fundamental cycles
        let fCycles = PathsAndCycles.fundamentalCycles(graph)
        if fCycles.isEmpty { return true }

        // Build cycle intersection / interlacing graph (conflict graph)
        let m = fCycles.count
        var conflictGraph = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<m), kind: .undirected)

        for i in 0..<m {
            for j in (i + 1)..<m {
                if cyclesInterlace(fCycles[i], fCycles[j]) {
                    _ = conflictGraph._addEdge(u: i, v: j)
                }
            }
        }

        // A graph is planar iff its cycle conflict graph is bipartite (2-colorable)
        return isBipartite(conflictGraph)
    }

    private static func cyclesInterlace(_ c1: [Int], _ c2: [Int]) -> Bool {
        let s1 = Set(c1)
        let s2 = Set(c2)
        let common = s1.intersection(s2)
        // Two cycles interlace if they share at least 2 non-adjacent vertices alternating along the cycles
        guard common.count >= 2 else { return false }

        var idxs1: [Int] = []
        for (idx, v) in c1.enumerated() {
            if common.contains(v) { idxs1.append(idx) }
        }
        var idxs2: [Int] = []
        for (idx, v) in c2.enumerated() {
            if common.contains(v) { idxs2.append(idx) }
        }

        return idxs1.count >= 4 && idxs2.count >= 4
    }

    private static func isBipartite<V, W>(_ graph: AdjacentGraph<V, W>) -> Bool {
        let n = graph.vertexCount
        var color = Array(repeating: -1, count: n)

        for root in 0..<n where color[root] == -1 {
            var queue = [root]
            color[root] = 0

            while !queue.isEmpty {
                let u = queue.removeFirst()
                for v in graph.adjacent(of: u) {
                    if color[v] == -1 {
                        color[v] = 1 - color[u]
                        queue.append(v)
                    } else if color[v] == color[u] {
                        return false
                    }
                }
            }
        }
        return true
    }
}
