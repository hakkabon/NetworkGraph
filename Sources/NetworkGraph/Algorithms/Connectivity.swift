//
//  Connectivity.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - 2.2 / 2.3 Traversal Event & Search Results

/// Edge classification during Depth-First Search.
public enum DFSEdgeType: Sendable {
    case tree
    case back
    case forward
    case cross
}

/// Detailed result of a full Depth-First Search.
public struct DFSResult: Sendable {
    public let discoveryTimes: [Int]
    public let finishTimes: [Int]
    public let predecessors: [Int?]
    public let edgeTypes: [Edge: DFSEdgeType]
    public let visitorOrder: [Int]
}

/// Detailed result of a Breadth-First Search.
public struct BFSResult: Sendable {
    public let distances: [Int: Int]
    public let predecessors: [Int?]
    public let layers: [[Int]]
    public let visitorOrder: [Int]
}

// MARK: - 2.6 Cut Nodes (Articulation Points) & Bridges Result

public struct CutResult: Sendable {
    /// Vertices whose removal increases the number of connected components.
    public let articulationPoints: Set<Int>
    /// Edges whose removal increases the number of connected components.
    public let bridges: Set<Edge>
}

// MARK: - 2.7 Strongly Connected Components Result

public struct SCCResult: Sendable {
    /// Each component is an array of vertex indices.
    public let components: [[Int]]
    /// Mapping from vertex index to its component ID.
    public let componentOf: [Int: Int]
    /// Condensation DAG where vertices are component IDs and edges represent inter-component connections.
    public let condensationDAG: AdjacentGraph<Int, NoProperty>
}

// MARK: - 2.10 Minimum Spanning Tree Result

public struct MSTResult<W: BinaryFloatingPoint & Hashable & Codable & Sendable>: Sendable {
    /// The edges included in the minimum spanning tree / forest.
    public let edges: [Edge]
    /// Total weight of all edges in the MST.
    public let totalWeight: Double
    /// The spanning tree as an `AdjacentGraph`.
    public let treeGraph: AdjacentGraph<Int, W>
}

// MARK: - Connectivity Algorithms

public enum Connectivity {

    // MARK: - 2.1 Maximum Connectivity (Harary Graphs)

    /// Constructs a $k$-connected Harary graph $H_{k, n}$ on $n$ vertices with minimum possible number of edges ($\lceil k \cdot n / 2 \rceil$).
    ///
    /// - Parameters:
    ///   - k: Desired connectivity ($1 \le k < n$).
    ///   - n: Number of vertices ($n \ge 3$).
    /// - Returns: A $k$-connected undirected `AdjacentGraph<Int, NoProperty>`.
    public static func hararyGraph(k: Int, n: Int) throws -> AdjacentGraph<Int, NoProperty> {
        guard n >= 3 else {
            throw NetworkGraphError.illegalArgument(cause: "Harary graphs require n >= 3")
        }
        guard k >= 1 && k < n else {
            throw NetworkGraphError.illegalArgument(cause: "Connectivity k must satisfy 1 <= k < n")
        }

        var graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<n), kind: .undirected)

        // Case 1: k is even, connect i to (i + j) mod n for 1 <= j <= k/2
        let r = k / 2
        for i in 0..<n {
            for j in 1...r {
                let target = (i + j) % n
                if !graph.isAdjacent(u: i, v: target) {
                    _ = graph._addEdge(u: i, v: target)
                }
            }
        }

        // Case 2: k is odd and n is even, add diameter chords (i, i + n/2)
        if k % 2 != 0 && n % 2 == 0 {
            let half = n / 2
            for i in 0..<half {
                let target = i + half
                if !graph.isAdjacent(u: i, v: target) {
                    _ = graph._addEdge(u: i, v: target)
                }
            }
        } else if k % 2 != 0 && n % 2 != 0 {
            // Case 3: k is odd and n is odd, connect 0 to (n-1)/2 and (n+1)/2, and i to i + (n+1)/2 for 1 <= i < (n-1)/2
            let half = (n - 1) / 2
            if !graph.isAdjacent(u: 0, v: half) { _ = graph._addEdge(u: 0, v: half) }
            if !graph.isAdjacent(u: 0, v: half + 1) { _ = graph._addEdge(u: 0, v: half + 1) }
            for i in 1..<half {
                let target = (i + half + 1) % n
                if !graph.isAdjacent(u: i, v: target) {
                    _ = graph._addEdge(u: i, v: target)
                }
            }
        }

        return graph
    }

    // MARK: - 2.2 Depth-First Search (Full Classification)

    public static func dfs<V, W>(
        graph: AdjacentGraph<V, W>,
        startVertex: Int? = nil,
        visitor: ((Int) -> Void)? = nil
    ) -> DFSResult {
        let V_count = graph.vertexCount
        var discovery = Array(repeating: -1, count: V_count)
        var finish = Array(repeating: -1, count: V_count)
        var pred = Array<Int?>(repeating: nil, count: V_count)
        var edgeTypes: [Edge: DFSEdgeType] = [:]
        var order: [Int] = []
        var timer = 0

        func dfsVisit(_ start: Int) {
            timer += 1
            discovery[start] = timer
            order.append(start)
            visitor?(start)

            var stack: [(u: Int, neighbors: [Int], nextIndex: Int)] = [(start, graph.adjacent(of: start), 0)]

            while !stack.isEmpty {
                let currentIdx = stack.count - 1
                let u = stack[currentIdx].u
                let neighbors = stack[currentIdx].neighbors
                let nextIdx = stack[currentIdx].nextIndex

                if nextIdx < neighbors.count {
                    let v = neighbors[nextIdx]
                    stack[currentIdx].nextIndex += 1
                    let e = Edge(u: u, v: v)

                    if discovery[v] == -1 {
                        edgeTypes[e] = .tree
                        pred[v] = u
                        timer += 1
                        discovery[v] = timer
                        order.append(v)
                        visitor?(v)
                        stack.append((v, graph.adjacent(of: v), 0))
                    } else if finish[v] == -1 {
                        edgeTypes[e] = .back
                    } else if discovery[u] < discovery[v] {
                        edgeTypes[e] = .forward
                    } else {
                        edgeTypes[e] = .cross
                    }
                } else {
                    stack.removeLast()
                    timer += 1
                    finish[u] = timer
                }
            }
        }

        if let s = startVertex, s >= 0, s < V_count {
            dfsVisit(s)
        }
        for u in 0..<V_count {
            if discovery[u] == -1 {
                dfsVisit(u)
            }
        }

        return DFSResult(
            discoveryTimes: discovery,
            finishTimes: finish,
            predecessors: pred,
            edgeTypes: edgeTypes,
            visitorOrder: order
        )
    }

    /// DFS overload accepting a `Visitor` conforming instance.
    public static func dfs<V, W, Vis: Visitor>(
        graph: AdjacentGraph<V, W>,
        startVertex: Int? = nil,
        visitor: Vis
    ) -> DFSResult where Vis.Vertex == Int {
        dfs(graph: graph, startVertex: startVertex, visitor: { visitor.visit(vertex: $0) })
    }

    // MARK: - 2.3 Breadth-First Search (Full Layered)

    public static func bfs<V, W>(
        graph: AdjacentGraph<V, W>,
        startVertex: Int,
        visitor: ((Int) -> Void)? = nil
    ) -> BFSResult {
        let V_count = graph.vertexCount
        var distances = [Int: Int]()
        var predecessors = Array<Int?>(repeating: nil, count: V_count)
        var visited = Set<Int>()
        var order: [Int] = []
        var layers: [[Int]] = []

        guard startVertex >= 0 && startVertex < V_count else {
            return BFSResult(distances: distances, predecessors: predecessors, layers: layers, visitorOrder: order)
        }

        var currentLayer = [startVertex]
        visited.insert(startVertex)
        distances[startVertex] = 0
        order.append(startVertex)
        visitor?(startVertex)

        while !currentLayer.isEmpty {
            layers.append(currentLayer)
            var nextLayer: [Int] = []
            for u in currentLayer {
                let distU = distances[u]!
                for v in graph.adjacent(of: u) {
                    if !visited.contains(v) {
                        visited.insert(v)
                        distances[v] = distU + 1
                        predecessors[v] = u
                        order.append(v)
                        visitor?(v)
                        nextLayer.append(v)
                    }
                }
            }
            currentLayer = nextLayer
        }

        return BFSResult(
            distances: distances,
            predecessors: predecessors,
            layers: layers,
            visitorOrder: order
        )
    }

    /// BFS overload accepting a `Visitor` conforming instance.
    public static func bfs<V, W, Vis: Visitor>(
        graph: AdjacentGraph<V, W>,
        startVertex: Int,
        visitor: Vis
    ) -> BFSResult where Vis.Vertex == Int {
        bfs(graph: graph, startVertex: startVertex, visitor: { visitor.visit(vertex: $0) })
    }

    // MARK: - 2.4 Connected Graph Testing

    public static func isConnected<V, W>(_ graph: AdjacentGraph<V, W>) -> Bool {
        guard graph.vertexCount > 0 else { return true }
        if graph.kind == .undirected {
            return graph.reachable(from: 0).count == graph.vertexCount
        } else {
            // Strongly connected test for directed graph
            let scc = stronglyConnectedComponents(graph)
            return scc.components.count == 1
        }
    }

    // MARK: - 2.5 Connected Components (Undirected)

    public static func connectedComponents<V, W>(_ graph: AdjacentGraph<V, W>) -> [[Int]] {
        let n = graph.vertexCount
        guard n > 0 else { return [] }
        var ds = DisjointSet(size: n)
        for edge in graph.edges {
            ds.union(edge.u, edge.v)
        }

        var groups: [Int: [Int]] = [:]
        for i in 0..<n {
            let root = ds.find(i)
            groups[root, default: []].append(i)
        }
        return groups.values.map { $0.sorted() }.sorted { $0.first! < $1.first! }
    }

    // MARK: - 2.6 Cut Nodes & Bridges (Hopcroft-Tarjan O(V+E))

    public static func findCutNodesAndBridges<V, W>(_ graph: AdjacentGraph<V, W>) -> CutResult {
        let n = graph.vertexCount
        var disc = Array(repeating: -1, count: n)
        var low = Array(repeating: -1, count: n)
        var timer = 0
        var articulationPoints = Set<Int>()
        var bridges = Set<Edge>()

        func dfs(_ u: Int, _ p: Int) {
            timer += 1
            disc[u] = timer
            low[u] = timer
            var children = 0

            for v in graph.adjacent(of: u) {
                if v == p { continue }
                if disc[v] != -1 {
                    low[u] = Swift.min(low[u], disc[v])
                } else {
                    children += 1
                    dfs(v, u)
                    low[u] = Swift.min(low[u], low[v])

                    // Articulation point condition for non-root
                    if p != -1 && low[v] >= disc[u] {
                        articulationPoints.insert(u)
                    }
                    // Bridge condition
                    if low[v] > disc[u] {
                        bridges.insert(Edge(u: Swift.min(u, v), v: Swift.max(u, v)))
                    }
                }
            }

            // Articulation point condition for root
            if p == -1 && children > 1 {
                articulationPoints.insert(u)
            }
        }

        for i in 0..<n {
            if disc[i] == -1 {
                dfs(i, -1)
            }
        }

        return CutResult(articulationPoints: articulationPoints, bridges: bridges)
    }

    // MARK: - 2.7 Strongly Connected Components (Tarjan's Algorithm)

    public static func stronglyConnectedComponents<V, W>(_ graph: AdjacentGraph<V, W>) -> SCCResult {
        let n = graph.vertexCount
        var disc = Array(repeating: -1, count: n)
        var low = Array(repeating: -1, count: n)
        var onStack = Array(repeating: false, count: n)
        var stack: [Int] = []
        var timer = 0

        var components: [[Int]] = []
        var componentOf = [Int: Int]()

        func dfs(_ u: Int) {
            timer += 1
            disc[u] = timer
            low[u] = timer
            stack.append(u)
            onStack[u] = true

            for v in graph.adjacent(of: u) {
                if disc[v] == -1 {
                    dfs(v)
                    low[u] = Swift.min(low[u], low[v])
                } else if onStack[v] {
                    low[u] = Swift.min(low[u], disc[v])
                }
            }

            if low[u] == disc[u] {
                var comp: [Int] = []
                let compId = components.count
                while true {
                    let v = stack.removeLast()
                    onStack[v] = false
                    comp.append(v)
                    componentOf[v] = compId
                    if v == u { break }
                }
                components.append(comp.sorted())
            }
        }

        for i in 0..<n {
            if disc[i] == -1 {
                dfs(i)
            }
        }

        // Build condensation DAG
        var dag = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<components.count), kind: .directed)
        var dagEdgeSet = Set<Edge>()

        for edge in graph.edges {
            if let cU = componentOf[edge.u], let cV = componentOf[edge.v], cU != cV {
                let e = Edge(u: cU, v: cV)
                if !dagEdgeSet.contains(e) {
                    dagEdgeSet.insert(e)
                    _ = dag._addEdge(u: cU, v: cV)
                }
            }
        }

        return SCCResult(
            components: components,
            componentOf: componentOf,
            condensationDAG: dag
        )
    }

    // MARK: - 2.8 Minimal Equivalent Graph (Transitive Reduction)

    /// Computes the minimal equivalent graph (transitive reduction) that preserves reachability with minimum edges.
    public static func minimalEquivalentGraph<V, W>(_ graph: AdjacentGraph<V, W>) -> AdjacentGraph<V, NoProperty> {
        var reduced = AdjacentGraph<V, NoProperty>(vertices: graph.vertices, kind: graph.kind)

        // For each edge (u, v), test if there is an alternative path from u to v without using direct edge (u, v)
        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }

            // BFS from edge.u to edge.v ignoring direct edge
            var visited = Set<Int>([edge.u])
            var queue = [edge.u]
            var hasAltPath = false

            while !queue.isEmpty && !hasAltPath {
                let curr = queue.removeFirst()
                for neighbor in graph.adjacent(of: curr) {
                    // Skip direct edge on initial step
                    if curr == edge.u && neighbor == edge.v { continue }
                    if neighbor == edge.v {
                        hasAltPath = true
                        break
                    }
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        queue.append(neighbor)
                    }
                }
            }

            if !hasAltPath {
                _ = reduced._addEdge(u: edge.u, v: edge.v)
            }
        }

        return reduced
    }

    // MARK: - 2.9 Edge Connectivity (Stoer-Wagner Min-Cut)

    /// Computes the global minimum edge cut and edge connectivity $\lambda(G)$ for an undirected weighted graph.
    public static func globalMinCut<V, W: BinaryFloatingPoint>(graph: AdjacentGraph<V, W>) -> (minCut: Double, partition: [Int]) {
        let n = graph.vertexCount
        guard n >= 2 else { return (0, Array(0..<n)) }

        // Adjacency matrix for edge contraction
        var mat = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let w = Double(graph.edgeProperties[edge] ?? W(1))
            mat[edge.u][edge.v] += w
            mat[edge.v][edge.u] += w
        }

        var nodeGroups: [[Int]] = (0..<n).map { [$0] }
        var bestCut = Double.infinity
        var bestPartition: [Int] = []

        var active = Array(0..<n)

        for _ in 0..<(n - 1) {
            var weights = Array(repeating: 0.0, count: n)
            var added = Array(repeating: false, count: n)
            var prev = -1
            var last = -1

            for _ in 0..<active.count {
                var maxW = -1.0
                var next = -1
                for u in active {
                    if !added[u] && weights[u] > maxW {
                        maxW = weights[u]
                        next = u
                    }
                }
                if next == -1 {
                    next = active.first { !added[$0] }!
                }
                added[next] = true
                prev = last
                last = next
                for v in active where !added[v] {
                    weights[v] += mat[next][v]
                }
            }

            let cutWeight = weights[last]
            if cutWeight < bestCut {
                bestCut = cutWeight
                bestPartition = nodeGroups[last]
            }

            // Merge `last` into `prev`
            nodeGroups[prev].append(contentsOf: nodeGroups[last])
            for v in active {
                mat[prev][v] += mat[last][v]
                mat[v][prev] += mat[v][last]
            }
            active.removeAll { $0 == last }
        }

        return (bestCut, bestPartition.sorted())
    }

    // MARK: - 2.10 Minimum Spanning Tree (Kruskal's Algorithm)

    public static func minimumSpanningTree<V, W: BinaryFloatingPoint & Hashable & Codable>(
        graph: AdjacentGraph<V, W>
    ) -> MSTResult<W> {
        let n = graph.vertexCount
        guard n > 0 else {
            return MSTResult(edges: [], totalWeight: 0, treeGraph: AdjacentGraph(vertices: [], kind: .undirected))
        }

        // Collect all distinct undirected edges sorted by weight
        var edgeList: [(Edge, Double)] = []
        var seen = Set<Edge>()

        for e in graph.edges {
            let norm = Edge(u: Swift.min(e.u, e.v), v: Swift.max(e.u, e.v))
            if !seen.contains(norm) {
                seen.insert(norm)
                let w = Double(graph.edgeProperties[e] ?? W(0))
                edgeList.append((norm, w))
            }
        }
        edgeList.sort { $0.1 < $1.1 }

        var ds = DisjointSet(size: n)
        var mstEdges: [Edge] = []
        var totalWeight: Double = 0
        var treeGraph = AdjacentGraph<Int, W>(vertices: Array(0..<n), kind: .undirected)

        for (e, w) in edgeList {
            if ds.union(e.u, e.v) {
                mstEdges.append(e)
                totalWeight += w
                _ = treeGraph._addEdge(u: e.u, v: e.v)
                treeGraph[e] = W(w)
                if mstEdges.count == n - 1 { break }
            }
        }

        return MSTResult(edges: mstEdges, totalWeight: totalWeight, treeGraph: treeGraph)
    }

    // MARK: - 2.11 All Cliques (Bron-Kerbosch with Pivoting)

    /// Finds all maximal cliques in an undirected graph using the Bron-Kerbosch algorithm with pivoting.
    ///
    /// - Returns: A list of maximal cliques (each an array of vertex indices).
    public static func allMaximalCliques<V, W>(_ graph: AdjacentGraph<V, W>) -> [[Int]] {
        let n = graph.vertexCount
        guard n > 0 else { return [] }

        var adjSets = Array(repeating: Set<Int>(), count: n)
        for u in 0..<n {
            adjSets[u] = Set(graph.adjacent(of: u))
        }

        var result: [[Int]] = []

        func bronKerbosch(r: Set<Int>, p: inout Set<Int>, x: inout Set<Int>) {
            if p.isEmpty && x.isEmpty {
                result.append(r.sorted())
                return
            }

            // Pivot selection: choose u from P ∪ X that maximizes |P ∩ N(u)|
            let unionPX = p.union(x)
            guard let pivot = unionPX.max(by: { p.intersection(adjSets[$0]).count < p.intersection(adjSets[$1]).count }) else { return }

            let candidates = p.subtracting(adjSets[pivot])
            for v in candidates {
                let nV = adjSets[v]
                var nextP = p.intersection(nV)
                var nextX = x.intersection(nV)
                bronKerbosch(r: r.union([v]), p: &nextP, x: &nextX)
                p.remove(v)
                x.insert(v)
            }
        }

        var p = Set(0..<n)
        var x = Set<Int>()
        bronKerbosch(r: [], p: &p, x: &x)

        return result.sorted { $0.count > $1.count }
    }

    /// Finds the maximum clique (clique of maximum cardinality $\omega(G)$).
    public static func maximumClique<V, W>(_ graph: AdjacentGraph<V, W>) -> [Int] {
        allMaximalCliques(graph).first ?? []
    }
}
