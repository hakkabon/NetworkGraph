//
//  Matching.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Result of a graph matching computation.
public struct MatchingResult: Sendable {
    /// The number of matched edges in the matching ($|M|$).
    public let cardinality: Int
    /// Array of matched pairs $(u, v)$ in the matching.
    public let matchedEdges: [Edge]
    /// Mapping from vertex to its matched partner (or `nil` if unmatched).
    public let matchOf: [Int: Int]
    /// Optional total weight of the matching (for weighted matching / min-sum assignment).
    public let totalWeight: Double?
}

/// Graph Matching algorithms (Topic 7).
public enum GraphMatching {

    // MARK: - 7.1 Maximum Cardinality Matching (Hopcroft-Karp for Bipartite)

    /// Computes a maximum cardinality matching in a bipartite graph using the Hopcroft-Karp algorithm ($O(E \sqrt{V})$).
    ///
    /// - Parameters:
    ///   - graph: A bipartite graph.
    ///   - partitionV1: Set of vertices in the first partition ($V_1$).
    /// - Returns: A `MatchingResult` containing the maximum matching.
    public static func hopcroftKarp<V, W>(
        graph: AdjacentGraph<V, W>,
        partitionV1: Set<Int>
    ) -> MatchingResult {
        let n = graph.vertexCount
        var pairU = Array(repeating: -1, count: n) // pair of u in V1
        var pairV = Array(repeating: -1, count: n) // pair of v in V2
        var dist = Array(repeating: -1, count: n)

        func bfs() -> Bool {
            var queue: [Int] = []
            for u in partitionV1 {
                if pairU[u] == -1 {
                    dist[u] = 0
                    queue.append(u)
                } else {
                    dist[u] = -1
                }
            }

            var foundAugmenting = false

            while !queue.isEmpty {
                let u = queue.removeFirst()
                for v in graph.adjacent(of: u) where !partitionV1.contains(v) {
                    let nextU = pairV[v]
                    if nextU == -1 {
                        foundAugmenting = true
                    } else if dist[nextU] == -1 {
                        dist[nextU] = dist[u] + 1
                        queue.append(nextU)
                    }
                }
            }

            return foundAugmenting
        }

        func dfs(_ u: Int) -> Bool {
            for v in graph.adjacent(of: u) where !partitionV1.contains(v) {
                let nextU = pairV[v]
                if nextU == -1 || (dist[nextU] == dist[u] + 1 && dfs(nextU)) {
                    pairV[v] = u
                    pairU[u] = v
                    return true
                }
            }
            dist[u] = -1
            return false
        }

        var matchingSize = 0
        while bfs() {
            for u in partitionV1 where pairU[u] == -1 {
                if dfs(u) {
                    matchingSize += 1
                }
            }
        }

        var matchedEdges: [Edge] = []
        var matchMap: [Int: Int] = [:]

        for u in partitionV1 where pairU[u] != -1 {
            let v = pairU[u]
            matchedEdges.append(Edge(u: u, v: v))
            matchMap[u] = v
            matchMap[v] = u
        }

        return MatchingResult(
            cardinality: matchingSize,
            matchedEdges: matchedEdges,
            matchOf: matchMap,
            totalWeight: nil
        )
    }

    // MARK: - 7.1 Edmonds' Blossom Algorithm (General Maximum Cardinality Matching)

    /// Computes a maximum cardinality matching in an arbitrary general undirected graph using Edmonds' Blossom algorithm ($O(V^2 E)$).
    public static func edmondsBlossom<V, W>(_ graph: AdjacentGraph<V, W>) -> MatchingResult {
        let n = graph.vertexCount
        var match = Array(repeating: -1, count: n)
        var p = Array(repeating: -1, count: n)
        var base = Array(0..<n)
        var used = Array(repeating: false, count: n)
        var blossom = Array(repeating: false, count: n)

        func lca(_ a: Int, _ b: Int) -> Int {
            var visited = Array(repeating: false, count: n)
            var u = a
            while true {
                u = base[u]
                visited[u] = true
                if match[u] == -1 { break }
                u = p[match[u]]
            }
            var v = b
            while true {
                v = base[v]
                if visited[v] { return v }
                v = p[match[v]]
            }
        }

        func markBlossom(_ lcaNode: Int, _ u: Int) {
            var curr = u
            while base[curr] != lcaNode {
                let v = match[curr]
                blossom[base[curr]] = true
                blossom[base[v]] = true
                p[curr] = v
                curr = p[v]
            }
        }

        func findPath(_ root: Int) -> Int {
            used = Array(repeating: false, count: n)
            p = Array(repeating: -1, count: n)
            base = Array(0..<n)

            var queue = [root]
            used[root] = true

            while !queue.isEmpty {
                let v = queue.removeFirst()
                for to in graph.adjacent(of: v) {
                    if base[v] == base[to] || match[v] == to { continue }
                    if to == root || (match[to] != -1 && p[match[to]] != -1) {
                        let curLCA = lca(v, to)
                        blossom = Array(repeating: false, count: n)
                        markBlossom(curLCA, v)
                        markBlossom(curLCA, to)
                        for i in 0..<n where blossom[base[i]] {
                            base[i] = curLCA
                            if !used[i] {
                                used[i] = true
                                queue.append(i)
                            }
                        }
                    } else if p[to] == -1 {
                        p[to] = v
                        if match[to] == -1 {
                            return to
                        }
                        to_match: do {
                            let m = match[to]
                            used[m] = true
                            queue.append(m)
                        }
                    }
                }
            }
            return -1
        }

        for i in 0..<n where match[i] == -1 {
            let v = findPath(i)
            if v != -1 {
                var curr = v
                while curr != -1 {
                    let pv = p[curr]
                    let ppv = pv != -1 ? match[pv] : -1
                    match[curr] = pv
                    if pv != -1 { match[pv] = curr }
                    curr = ppv
                }
            }
        }

        var matchedEdges: [Edge] = []
        var matchMap: [Int: Int] = [:]
        var count = 0

        for i in 0..<n {
            if match[i] != -1 && i < match[i] {
                matchedEdges.append(Edge(u: i, v: match[i]))
                matchMap[i] = match[i]
                matchMap[match[i]] = i
                count += 1
            }
        }

        return MatchingResult(
            cardinality: count,
            matchedEdges: matchedEdges,
            matchOf: matchMap,
            totalWeight: nil
        )
    }

    // MARK: - 7.2 Hungarian (Munkres) Algorithm for Minimum Sum Perfect Matching

    /// Solves the Minimum Sum Perfect Matching / Assignment Problem on an $n \times n$ cost matrix in $O(n^3)$ time.
    ///
    /// - Parameter costMatrix: An $n \times n$ cost matrix where $c_{ij}$ is the cost of matching worker $i$ to job $j$.
    /// - Returns: A `MatchingResult` containing optimal assignment pairs and minimum total cost.
    public static func hungarianAssignment(costMatrix: [[Double]]) -> (assignment: [Int], totalCost: Double) {
        let n = costMatrix.count
        guard n > 0 else { return ([], 0.0) }

        // Hungarian algorithm using 1-based potential vectors u, v
        var u = Array(repeating: 0.0, count: n + 1)
        var v = Array(repeating: 0.0, count: n + 1)
        var p = Array(repeating: 0, count: n + 1)
        var way = Array(repeating: 0, count: n + 1)

        for i in 1...n {
            p[0] = i
            var j0 = 0
            var minv = Array(repeating: Double.infinity, count: n + 1)
            var used = Array(repeating: false, count: n + 1)

            repeat {
                used[j0] = true
                let i0 = p[j0]
                var delta = Double.infinity
                var j1 = 0

                for j in 1...n {
                    if !used[j] {
                        let cur = costMatrix[i0 - 1][j - 1] - u[i0] - v[j]
                        if cur < minv[j] {
                            minv[j] = cur
                            way[j] = j0
                        }
                        if minv[j] < delta {
                            delta = minv[j]
                            j1 = j
                        }
                    }
                }

                for j in 0...n {
                    if used[j] {
                        u[p[j]] += delta
                        v[j] -= delta
                    } else {
                        minv[j] -= delta
                    }
                }

                j0 = j1
            } while p[j0] != 0

            repeat {
                let j1 = way[j0]
                p[j0] = p[j1]
                j0 = j1
            } while j0 != 0
        }

        var assignment = Array(repeating: -1, count: n)
        for j in 1...n {
            if p[j] > 0 {
                assignment[p[j] - 1] = j - 1
            }
        }

        let totalCost = -v[0]
        return (assignment, totalCost)
    }

    /// Computes minimum weight bipartite matching from a weighted `AdjacentGraph` with bipartition `partitionV1`.
    public static func minimumWeightBipartiteMatching<V, W: BinaryFloatingPoint>(
        graph: AdjacentGraph<V, W>,
        partitionV1: Set<Int>
    ) -> MatchingResult {
        let v1 = Array(partitionV1).sorted()
        let v2 = (0..<graph.vertexCount).filter { !partitionV1.contains($0) }.sorted()
        let size = Swift.max(v1.count, v2.count)

        // Build cost matrix padded with high costs for dummy vertices
        var costMatrix = Array(repeating: Array(repeating: 1e9, count: size), count: size)

        for (i, u) in v1.enumerated() {
            for (j, v) in v2.enumerated() {
                if graph.isAdjacent(u: u, v: v) {
                    let w = Double(graph.edgeProperties[Edge(u: u, v: v)] ?? graph.edgeProperties[Edge(u: v, v: u)] ?? W(0))
                    costMatrix[i][j] = w
                }
            }
        }

        let (assignment, _) = hungarianAssignment(costMatrix: costMatrix)

        var matchedEdges: [Edge] = []
        var matchMap: [Int: Int] = [:]
        var totalWeight = 0.0

        for (i, j) in assignment.enumerated() {
            if i < v1.count && j < v2.count {
                let u = v1[i]
                let v = v2[j]
                if graph.isAdjacent(u: u, v: v) {
                    let w = Double(graph.edgeProperties[Edge(u: u, v: v)] ?? graph.edgeProperties[Edge(u: v, v: u)] ?? W(0))
                    matchedEdges.append(Edge(u: u, v: v))
                    matchMap[u] = v
                    matchMap[v] = u
                    totalWeight += w
                }
            }
        }

        return MatchingResult(
            cardinality: matchedEdges.count,
            matchedEdges: matchedEdges,
            matchOf: matchMap,
            totalWeight: totalWeight
        )
    }
}
