//
//  PathsAndCycles.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Result Types

/// Result of an All-Pairs Shortest Path computation (Floyd-Warshall / Johnson).
public struct APSPResult: Sendable {
    /// Matrix of shortest path distances where `matrix[u][v]` is distance from $u$ to $v$.
    public let distances: [[Double]]
    /// Predecessor matrix for path reconstruction.
    public let nextVertex: [[Int?]]

    /// Reconstructs the shortest path between `source` and `target`.
    public func path(from source: Int, to target: Int) -> [Int]? {
        guard distances[source][target] != .infinity else { return nil }
        var path = [source]
        var curr = source
        while curr != target {
            guard let next = nextVertex[curr][target] else { return nil }
            curr = next
            path.append(curr)
        }
        return path
    }
}

/// Result of a Traveling Salesman Problem computation.
public struct TSPResult: Sendable {
    /// Ordered sequence of vertices visited in the cycle.
    public let tour: [Int]
    /// Total length / cost of the tour.
    public let totalCost: Double
}

/// Result of an Eulerian Circuit / Trail computation.
public struct EulerResult: Sendable {
    /// Ordered sequence of vertices in the Eulerian tour.
    public let vertices: [Int]
    /// Ordered sequence of edges traversed.
    public let edges: [Edge]
    public let isCircuit: Bool
}

// MARK: - Paths and Cycles Algorithms

public enum PathsAndCycles {

    // MARK: - 3.1 Fundamental Set of Cycles

    /// Computes a fundamental cycle basis of an undirected connected graph using a spanning tree.
    public static func fundamentalCycles<V, W>(_ graph: AdjacentGraph<V, W>) -> [[Int]] {
        let n = graph.vertexCount
        guard n >= 3 else { return [] }

        // 1. Build spanning tree using BFS
        var treeEdges = Set<Edge>()
        var parent = Array(repeating: -1, count: n)
        var depth = Array(repeating: 0, count: n)
        var visited = Array(repeating: false, count: n)

        for root in 0..<n where !visited[root] {
            var queue = [root]
            visited[root] = true

            while !queue.isEmpty {
                let u = queue.removeFirst()
                for v in graph.adjacent(of: u) {
                    if !visited[v] {
                        visited[v] = true
                        parent[v] = u
                        depth[v] = depth[u] + 1
                        let e = Edge(u: Swift.min(u, v), v: Swift.max(u, v))
                        treeEdges.insert(e)
                        queue.append(v)
                    }
                }
            }
        }

        // 2. For each non-tree edge (u, v), trace paths to their lowest common ancestor (LCA)
        var cycleBasis: [[Int]] = []
        var seenChords = Set<Edge>()

        for e in graph.edges {
            let norm = Edge(u: Swift.min(e.u, e.v), v: Swift.max(e.u, e.v))
            if norm.u == norm.v || treeEdges.contains(norm) || seenChords.contains(norm) { continue }
            seenChords.insert(norm)

            var u = norm.u
            var v = norm.v
            var pathU = [u]
            var pathV = [v]

            while u != v {
                if depth[u] > depth[v] {
                    u = parent[u]
                    pathU.append(u)
                } else if depth[v] > depth[u] {
                    v = parent[v]
                    pathV.append(v)
                } else {
                    u = parent[u]
                    v = parent[v]
                    pathU.append(u)
                    pathV.append(v)
                }
            }

            // Combine pathU + reversed pathV (without duplicating LCA)
            pathV.removeLast()
            let fullCycle = pathU + pathV.reversed()
            cycleBasis.append(fullCycle)
        }

        return cycleBasis
    }

    // MARK: - 3.2 Shortest Cycle Length (Girth)

    /// Computes the girth (length of shortest cycle) of an unweighted graph in $O(V(V+E))$ time. Returns $\infty$ if acyclic.
    public static func girth<V, W>(_ graph: AdjacentGraph<V, W>) -> Int {
        let n = graph.vertexCount
        var minGirth = Int.max

        for root in 0..<n {
            var dist = Array(repeating: -1, count: n)
            var parent = Array(repeating: -1, count: n)
            var queue = [root]
            dist[root] = 0

            while !queue.isEmpty {
                let u = queue.removeFirst()
                for v in graph.adjacent(of: u) {
                    if dist[v] == -1 {
                        dist[v] = dist[u] + 1
                        parent[v] = u
                        queue.append(v)
                    } else if parent[u] != v && (graph.kind == .directed || parent[v] != u) {
                        let cycleLen = dist[u] + dist[v] + 1
                        minGirth = Swift.min(minGirth, cycleLen)
                    }
                }
            }
        }

        return minGirth == Int.max ? -1 : minGirth
    }

    // MARK: - 3.3 One-Pair Shortest Path (Bidirectional Dijkstra)

    public static func bidirectionalDijkstra<V, W: BinaryFloatingPoint>(
        graph: AdjacentGraph<V, W>,
        source: Int,
        target: Int
    ) -> (distance: Double, path: [Int])? {
        if source == target { return (0, [source]) }
        let n = graph.vertexCount

        var distF = Array(repeating: Double.infinity, count: n)
        var distB = Array(repeating: Double.infinity, count: n)
        var predF = Array<Int?>(repeating: nil, count: n)
        var predB = Array<Int?>(repeating: nil, count: n)
        var visitedF = Set<Int>()
        var visitedB = Set<Int>()

        distF[source] = 0
        distB[target] = 0

        var pqF = PriorityQueue<Entry>(ascending: true, startingValues: [Entry(dist: 0, vertex: source)])
        var pqB = PriorityQueue<Entry>(ascending: true, startingValues: [Entry(dist: 0, vertex: target)])

        var bestDist = Double.infinity
        var meetingNode: Int? = nil

        while let topF = pqF.peek(), let topB = pqB.peek() {
            if topF.dist + topB.dist >= bestDist {
                break
            }

            // Expand forward
            if !pqF.isEmpty {
                let currF = pqF.pop()!.vertex
                visitedF.insert(currF)
                for v in graph.adjacent(of: currF) {
                    let w = Double(graph.edgeProperties[Edge(u: currF, v: v)] ?? W(0))
                    let newD = distF[currF] + w
                    if newD < distF[v] {
                        distF[v] = newD
                        predF[v] = currF
                        pqF.push(Entry(dist: newD, vertex: v))
                    }
                    if visitedB.contains(v) && distF[currF] + w + distB[v] < bestDist {
                        bestDist = distF[currF] + w + distB[v]
                        meetingNode = v
                    }
                }
            }

            // Expand backward (using inEdges)
            if !pqB.isEmpty {
                let currB = pqB.pop()!.vertex
                visitedB.insert(currB)
                for (u, _) in graph.inEdges(vertex: currB) {
                    let w = Double(graph.edgeProperties[Edge(u: u, v: currB)] ?? W(0))
                    let newD = distB[currB] + w
                    if newD < distB[u] {
                        distB[u] = newD
                        predB[u] = currB
                        pqB.push(Entry(dist: newD, vertex: u))
                    }
                    if visitedF.contains(u) && distF[u] + w + distB[currB] < bestDist {
                        bestDist = distF[u] + w + distB[currB]
                        meetingNode = u
                    }
                }
            }
        }

        guard let meet = meetingNode, bestDist != .infinity else { return nil }

        // Reconstruct path
        var forwardPath = [meet]
        var curr = meet
        while curr != source {
            guard let p = predF[curr] else { break }
            forwardPath.append(p)
            curr = p
        }
        forwardPath.reverse()

        var backwardPath: [Int] = []
        curr = meet
        while curr != target {
            guard let next = predB[curr] else { break }
            backwardPath.append(next)
            curr = next
        }

        return (bestDist, forwardPath + backwardPath)
    }

    // MARK: - 3.4 All Shortest Path Length (Bellman-Ford)

    public static func bellmanFord<V, W: BinaryFloatingPoint>(
        graph: AdjacentGraph<V, W>,
        source: Int
    ) throws -> (distances: [Double], predecessors: [Int?]) {
        let n = graph.vertexCount
        var dist = Array(repeating: Double.infinity, count: n)
        var pred = Array<Int?>(repeating: nil, count: n)
        dist[source] = 0

        let edges = graph.edges

        for _ in 0..<(n - 1) {
            var updated = false
            for e in edges {
                let w = Double(graph.edgeProperties[e] ?? W(0))
                if dist[e.u] != .infinity && dist[e.u] + w < dist[e.v] {
                    dist[e.v] = dist[e.u] + w
                    pred[e.v] = e.u
                    updated = true
                }
            }
            if !updated { break }
        }

        // Negative cycle detection
        for e in edges {
            let w = Double(graph.edgeProperties[e] ?? W(0))
            if dist[e.u] != .infinity && dist[e.u] + w < dist[e.v] {
                throw NetworkGraphError.illegalArgument(cause: "Graph contains a negative-weight cycle")
            }
        }

        return (dist, pred)
    }

    // MARK: - 3.5 Shortest Path Tree

    public static func shortestPathTree<V, W: BinaryFloatingPoint & Hashable & Codable>(
        graph: AdjacentGraph<V, W>,
        source: Int
    ) -> AdjacentGraph<V, W> {
        let result = dijkstra(graph: graph, source: source)
        var tree = AdjacentGraph<V, W>(vertices: graph.vertices, kind: .directed)
        for (v, e) in result.predecessors {
            _ = tree.addEdge(u: e.u, v: v)
            if let prop = graph.edgeProperties[e] {
                tree[Edge(u: e.u, v: v)] = prop
            }
        }
        return tree
    }

    // MARK: - 3.6 All-Pairs Shortest Paths (Floyd-Warshall)

    public static func floydWarshall<V, W: BinaryFloatingPoint>(
        graph: AdjacentGraph<V, W>
    ) -> APSPResult {
        let n = graph.vertexCount
        var dist = Array(repeating: Array(repeating: Double.infinity, count: n), count: n)
        var next = Array(repeating: Array<Int?>(repeating: nil, count: n), count: n)

        for i in 0..<n {
            dist[i][i] = 0
            next[i][i] = i
        }

        for e in graph.edges {
            let w = Double(graph.edgeProperties[e] ?? W(0))
            if w < dist[e.u][e.v] {
                dist[e.u][e.v] = w
                next[e.u][e.v] = e.v
            }
        }

        for k in 0..<n {
            for i in 0..<n {
                for j in 0..<n {
                    if dist[i][k] != .infinity && dist[k][j] != .infinity {
                        if dist[i][k] + dist[k][j] < dist[i][j] {
                            dist[i][j] = dist[i][k] + dist[k][j]
                            next[i][j] = next[i][k]
                        }
                    }
                }
            }
        }

        return APSPResult(distances: dist, nextVertex: next)
    }

    // MARK: - 3.7 / 3.8 Yen's k-Shortest Paths (With and Without Repeated Nodes)

    public static func kShortestPaths<V, W: BinaryFloatingPoint & Hashable & Codable>(
        graph: AdjacentGraph<V, W>,
        source: Int,
        target: Int,
        k: Int,
        allowRepeatedNodes: Bool = false
    ) -> [(path: [Int], cost: Double)] {
        guard k > 0 else { return [] }

        // Helper to run Dijkstra on a masked graph
        func findShortestPath(disabledEdges: Set<Edge>, disabledVertices: Set<Int>) -> (path: [Int], cost: Double)? {
            var dist = [Int: Double]()
            var pred = [Int: Int]()
            var visited = Set<Int>()

            for i in 0..<graph.vertexCount { dist[i] = .infinity }
            dist[source] = 0

            var pq = PriorityQueue<Entry>(ascending: true, startingValues: [Entry(dist: 0, vertex: source)])

            while let entry = pq.pop() {
                let u = entry.vertex
                if u == target { break }
                guard !visited.contains(u) else { continue }
                visited.insert(u)

                for v in graph.adjacent(of: u) {
                    let e = Edge(u: u, v: v)
                    if disabledEdges.contains(e) || (disabledVertices.contains(v) && v != target) { continue }
                    let w = Double(graph.edgeProperties[e] ?? W(1))
                    let newD = entry.dist + w
                    if newD < (dist[v] ?? .infinity) {
                        dist[v] = newD
                        pred[v] = u
                        pq.push(Entry(dist: newD, vertex: v))
                    }
                }
            }

            guard dist[target] != .infinity, dist[target] != nil else { return nil }
            var p = [target]
            var curr = target
            while curr != source {
                guard let prv = pred[curr] else { return nil }
                p.append(prv)
                curr = prv
            }
            return (p.reversed(), dist[target]!)
        }

        guard let first = findShortestPath(disabledEdges: [], disabledVertices: []) else { return [] }

        var result = [first]
        var candidates: [(path: [Int], cost: Double)] = []

        for _ in 1..<k {
            let prevPath = result.last!.path
            for i in 0..<(prevPath.count - 1) {
                let spurNode = prevPath[i]
                let rootPath = Array(prevPath[0...i])

                var disabledEdges = Set<Edge>()
                for r in result {
                    if r.path.count > i && Array(r.path[0...i]) == rootPath {
                        disabledEdges.insert(Edge(u: r.path[i], v: r.path[i + 1]))
                    }
                }

                let disabledVertices = allowRepeatedNodes ? Set<Int>() : Set(rootPath.dropLast())

                if let spur = findShortestPath(disabledEdges: disabledEdges, disabledVertices: disabledVertices) {
                    if let spurIdx = spur.path.firstIndex(of: spurNode) {
                        let totalP = rootPath.dropLast() + spur.path[spurIdx...]
                        var totalCost = 0.0
                        for idx in 0..<(totalP.count - 1) {
                            let e = Edge(u: totalP[idx], v: totalP[idx + 1])
                            totalCost += Double(graph.edgeProperties[e] ?? W(1))
                        }
                        if !candidates.contains(where: { $0.path == Array(totalP) }) && !result.contains(where: { $0.path == Array(totalP) }) {
                            candidates.append((Array(totalP), totalCost))
                        }
                    }
                }
            }

            guard !candidates.isEmpty else { break }
            candidates.sort { $0.cost < $1.cost }
            let nextBest = candidates.removeFirst()
            result.append(nextBest)
        }

        return result
    }

    // MARK: - 3.9 Euler Circuit (Hierholzer's Algorithm)

    public static func eulerCircuit<V, W>(_ graph: AdjacentGraph<V, W>) -> EulerResult? {
        let n = graph.vertexCount
        guard n > 0 else { return nil }

        var inDeg = Array(repeating: 0, count: n)
        var outDeg = Array(repeating: 0, count: n)

        for u in 0..<n {
            outDeg[u] = graph.degree(vertex: u)
            inDeg[u] = graph.indegree(vertex: u)
        }

        var startNode = 0
        var oddCount = 0

        if graph.kind == .undirected {
            for i in 0..<n {
                if graph.degree(vertex: i) % 2 != 0 {
                    oddCount += 1
                    startNode = i
                }
            }
            if oddCount != 0 && oddCount != 2 { return nil }
        } else {
            var startCount = 0
            var endCount = 0
            for i in 0..<n {
                let diff = outDeg[i] - inDeg[i]
                if diff == 1 {
                    startCount += 1
                    startNode = i
                } else if diff == -1 {
                    endCount += 1
                } else if diff != 0 {
                    return nil
                }
            }
            if (startCount != 0 || endCount != 0) && (startCount != 1 || endCount != 1) {
                return nil
            }
        }

        // Hierholzer's algorithm
        var adj = (0..<n).map { graph.adjacent(of: $0) }
        var edgeCountMap = [Edge: Int]()
        for e in graph.edges {
            edgeCountMap[e, default: 0] += 1
        }

        var stack = [startNode]
        var path: [Int] = []

        while !stack.isEmpty {
            let u = stack.last!
            if !adj[u].isEmpty {
                let v = adj[u].removeFirst()
                let e = Edge(u: u, v: v)
                if (edgeCountMap[e] ?? 0) > 0 {
                    edgeCountMap[e]! -= 1
                    if graph.kind == .undirected && u != v {
                        edgeCountMap[Edge(u: v, v: u)] = (edgeCountMap[Edge(u: v, v: u)] ?? 1) - 1
                    }
                    stack.append(v)
                }
            } else {
                path.append(stack.removeLast())
            }
        }

        path.reverse()
        var edgesTraversed: [Edge] = []
        for i in 0..<(path.count - 1) {
            edgesTraversed.append(Edge(u: path[i], v: path[i + 1]))
        }

        return EulerResult(
            vertices: path,
            edges: edgesTraversed,
            isCircuit: path.first == path.last
        )
    }

    // MARK: - 3.10 Hamilton Cycle (Held-Karp Exact DP)

    public static func hamiltonCycle<V, W: BinaryFloatingPoint>(_ graph: AdjacentGraph<V, W>) -> [Int]? {
        let n = graph.vertexCount
        guard n >= 3 else { return nil }
        if n > 20 {
            // Backtracking search for larger n
            return hamiltonBacktrack(graph)
        }

        let numStates = 1 << n
        var dp = Array(repeating: Array(repeating: false, count: n), count: numStates)
        var parent = Array(repeating: Array<Int?>(repeating: nil, count: n), count: numStates)

        dp[1][0] = true

        for mask in 1..<numStates {
            for u in 0..<n where (mask & (1 << u)) != 0 && dp[mask][u] {
                for v in graph.adjacent(of: u) where (mask & (1 << v)) == 0 {
                    let nextMask = mask | (1 << v)
                    dp[nextMask][v] = true
                    parent[nextMask][v] = u
                }
            }
        }

        let fullMask = numStates - 1
        var lastNode: Int? = nil
        for u in 0..<n {
            if dp[fullMask][u] && graph.isAdjacent(u: u, v: 0) {
                lastNode = u
                break
            }
        }

        guard let end = lastNode else { return nil }

        var tour = [0]
        var curr = end
        var mask = fullMask
        var pathRev = [end]

        while curr != 0 {
            guard let p = parent[mask][curr] else { break }
            pathRev.append(p)
            mask ^= (1 << curr)
            curr = p
        }

        pathRev.reverse()
        return pathRev + [0]
    }

    private static func hamiltonBacktrack<V, W>(_ graph: AdjacentGraph<V, W>) -> [Int]? {
        let n = graph.vertexCount
        var visited = Array(repeating: false, count: n)
        var path = [0]
        visited[0] = true

        func search(_ curr: Int) -> Bool {
            if path.count == n {
                return graph.isAdjacent(u: curr, v: 0)
            }
            for next in graph.adjacent(of: curr) where !visited[next] {
                visited[next] = true
                path.append(next)
                if search(next) { return true }
                path.removeLast()
                visited[next] = false
            }
            return false
        }

        if search(0) {
            path.append(0)
            return path
        }
        return nil
    }

    // MARK: - 3.11 Chinese Postman Tour

    public static func chinesePostmanTour<V, W: BinaryFloatingPoint & Hashable & Codable>(
        graph: AdjacentGraph<V, W>
    ) -> EulerResult? {
        let n = graph.vertexCount
        guard n > 0 else { return nil }

        // Find odd-degree vertices
        let oddVertices = (0..<n).filter { graph.degree(vertex: $0) % 2 != 0 }

        if oddVertices.isEmpty {
            return eulerCircuit(graph)
        }

        // All-pairs shortest paths
        let apsp = floydWarshall(graph: graph)

        // Minimum weight perfect matching on odd vertices
        var bestPairing: [(Int, Int)] = []
        var minPairingCost = Double.infinity

        func matchOdd(available: [Int], currentPairing: [(Int, Int)], currentCost: Double) {
            if available.isEmpty {
                if currentCost < minPairingCost {
                    minPairingCost = currentCost
                    bestPairing = currentPairing
                }
                return
            }
            let first = available[0]
            for i in 1..<available.count {
                let second = available[i]
                var rem = available
                rem.remove(at: i)
                rem.remove(at: 0)
                let cost = apsp.distances[first][second]
                matchOdd(available: rem, currentPairing: currentPairing + [(first, second)], currentCost: currentCost + cost)
            }
        }

        matchOdd(available: oddVertices, currentPairing: [], currentCost: 0)

        // Duplicate shortest path edges in the graph
        var augmented = graph
        for (u, v) in bestPairing {
            if let p = apsp.path(from: u, to: v) {
                for i in 0..<(p.count - 1) {
                    let a = p[i]
                    let b = p[i + 1]
                    _ = augmented.addEdge(u: a, v: b)
                    let w = graph.edgeProperties[Edge(u: a, v: b)] ?? graph.edgeProperties[Edge(u: b, v: a)] ?? W(1)
                    augmented[Edge(u: a, v: b)] = w
                }
            }
        }

        return eulerCircuit(augmented)
    }

    // MARK: - 3.12 Traveling Salesman Problem (Exact & Christofides)

    /// Solves TSP exactly via Held-Karp dynamic programming ($O(n^2 2^n)$) for $n \le 20$, or 2-opt heuristic for larger $n$.
    public static func travelingSalesman<V, W: BinaryFloatingPoint & Hashable & Codable>(
        graph: AdjacentGraph<V, W>
    ) -> TSPResult {
        let n = graph.vertexCount
        let apsp = floydWarshall(graph: graph)

        if n <= 18 {
            let numStates = 1 << n
            var dp = Array(repeating: Array(repeating: Double.infinity, count: n), count: numStates)
            var parent = Array(repeating: Array<Int?>(repeating: nil, count: n), count: numStates)

            dp[1][0] = 0

            for mask in 1..<numStates {
                for u in 0..<n where (mask & (1 << u)) != 0 && dp[mask][u] != .infinity {
                    let distU = dp[mask][u]
                    for v in 0..<n where (mask & (1 << v)) == 0 {
                        let costUV = apsp.distances[u][v]
                        if costUV != .infinity {
                            let nextMask = mask | (1 << v)
                            let newCost = distU + costUV
                            if newCost < dp[nextMask][v] {
                                dp[nextMask][v] = newCost
                                parent[nextMask][v] = u
                            }
                        }
                    }
                }
            }

            let fullMask = numStates - 1
            var bestEnd = -1
            var bestTotal = Double.infinity

            for u in 1..<n {
                let returnCost = apsp.distances[u][0]
                if dp[fullMask][u] != .infinity && returnCost != .infinity {
                    let total = dp[fullMask][u] + returnCost
                    if total < bestTotal {
                        bestTotal = total
                        bestEnd = u
                    }
                }
            }

            if bestEnd != -1 {
                var tour = [0]
                var curr = bestEnd
                var mask = fullMask
                var pathRev = [bestEnd]

                while curr != 0 {
                    guard let p = parent[mask][curr] else { break }
                    pathRev.append(p)
                    mask ^= (1 << curr)
                    curr = p
                }
                pathRev.reverse()
                return TSPResult(tour: pathRev + [0], totalCost: bestTotal)
            }
        }

        // Christofides / 2-Opt Heuristic Approximation
        return tsp2Opt(graph: graph, apsp: apsp)
    }

    private static func tsp2Opt<V, W: BinaryFloatingPoint>(
        graph: AdjacentGraph<V, W>,
        apsp: APSPResult
    ) -> TSPResult {
        let n = graph.vertexCount
        var tour = Array(0..<n) + [0]
        var improved = true

        func tourCost(_ t: [Int]) -> Double {
            var c = 0.0
            for i in 0..<(t.count - 1) {
                c += apsp.distances[t[i]][t[i + 1]]
            }
            return c
        }

        while improved {
            improved = false
            for i in 1..<(n - 1) {
                for j in (i + 1)..<n {
                    let d1 = apsp.distances[tour[i - 1]][tour[i]] + apsp.distances[tour[j]][tour[j + 1]]
                    let d2 = apsp.distances[tour[i - 1]][tour[j]] + apsp.distances[tour[i]][tour[j + 1]]
                    if d2 < d1 {
                        tour[i...j].reverse()
                        improved = true
                    }
                }
            }
        }

        return TSPResult(tour: tour, totalCost: tourCost(tour))
    }
}
