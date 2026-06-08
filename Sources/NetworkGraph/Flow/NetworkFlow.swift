//
//  NetworkFlow.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - FlowNetwork type alias

/// Convenience type alias for the most common flow-network graph configuration.
///
/// Use it directly, or substitute any `AdjacentGraph<V,W>` where `V` and `W`
/// satisfy the flow protocols.
public typealias FlowNetwork = AdjacentGraph<FlowVertex, FlowEdge>

// MARK: - NetworkFlowGraph conformance

extension AdjacentGraph: NetworkFlowGraph
where V: VertexAttributesProtocol, W == FlowEdge {

    public typealias FlowEdgeAttr = FlowEdge

    // --- Vertex ---

    public func vertexAttributes(at index: Int) -> V {
        vertex[index]
    }

    public mutating func setVertexAttributes(_ attrs: V, at index: Int) {
        vertex[index] = attrs
    }

    // --- Edge ---

    public func edgeAttributes(for edge: Edge) -> FlowEdge? {
        edgeProperties[edge]
    }

    public mutating func setEdgeAttributes(_ attrs: FlowEdge, for edge: Edge) {
        edgeProperties[edge] = attrs
    }

    // --- Default source / sink ---
    // Users can override these by creating a subtype or by using the
    // explicit API; the defaults point to first and last vertex.

    /// Index of the source vertex (first vertex by convention).
    public var source: Int { 0 }

    /// Index of the sink vertex (last vertex by convention).
    public var sink: Int { Swift.max(0, vertexCount - 1) }
}

// MARK: - Ford-Fulkerson max-flow

/// Computes the maximum flow from `source` to `sink` in a `FlowNetwork` using
/// the Ford-Fulkerson algorithm with BFS augmentation (Edmonds-Karp variant),
/// giving O(V · E²) worst-case complexity.
///
/// - Parameters:
///   - graph:  A `FlowNetwork` whose edge capacities have been set.
///   - source: Source vertex index.
///   - sink:   Sink vertex index.
/// - Returns: The maximum flow value and the mutated network with final flow values.
public func maxFlow(in graph: FlowNetwork,
                    from source: Int,
                    to sink: Int) -> (maxFlow: Double, network: FlowNetwork) {

    var net = graph
    // Reset all flows
    for key in net.edgeProperties.keys { net.edgeProperties[key]!.flow = 0 }

    var totalFlow: Double = 0

    while true {
        // BFS for an augmenting path in the residual graph
        guard let (path, bottleneck) = bfsAugmentingPath(net, source: source, sink: sink) else { break }

        // Push flow along the path
        for edge in path {
            let rev = edge.reversed()
            if net.edgeProperties[edge] != nil {
                // Forward arc: increase flow
                net.edgeProperties[edge]!.flow += bottleneck
            } else if net.edgeProperties[rev] != nil {
                // Backward (cancellation) arc: decrease flow on the reverse arc
                net.edgeProperties[rev]!.flow -= bottleneck
            }
        }
        totalFlow += bottleneck
    }

    return (totalFlow, net)
}

/// BFS over the residual graph; returns the augmenting path and its bottleneck,
/// or `nil` if no path exists.
///
/// The residual graph contains:
///   - A forward arc (u,v) with capacity = `attr.residualCapacity` whenever
///     the original arc (u,v) has spare capacity.
///   - A backward arc (v,u) with capacity = `attr.flow` whenever the original
///     arc (u,v) carries positive flow (cancellation arc).
private func bfsAugmentingPath(_ net: FlowNetwork,
                                source: Int,
                                sink: Int) -> ([Edge], Double)? {

    var parent = [Int: Edge]()   // parent[v] = the *residual* edge that reached v
    var visited = Set<Int>([source])
    var queue = [source]

    // Build a lookup: for each vertex v, which vertices have an arc TO v?
    // We need this to explore backward (cancellation) arcs.
    // We can derive it from net.inEdges(vertex:) because incoming lists are maintained.

    bfs:
    while !queue.isEmpty {
        let u = queue.removeFirst()
        if u == sink { break bfs }

        // --- Forward arcs (u,v): residual capacity = capacity − flow ---
        for v in net.adjacent(of: u) {
            let e = Edge(u: u, v: v)
            guard let attr = net.edgeProperties[e],
                  attr.residualCapacity > 0,
                  !visited.contains(v) else { continue }
            visited.insert(v)
            parent[v] = e
            queue.append(v)
            if v == sink { break bfs }
        }

        // --- Backward arcs (v,u): residual capacity = flow on (u,v) ---
        // A backward arc from u to some predecessor p exists when arc (p,u) has flow > 0.
        for (p, _) in net.inEdges(vertex: u) {
            let fwdEdge = Edge(u: p, v: u)
            guard let attr = net.edgeProperties[fwdEdge],
                  attr.flow > 0,
                  !visited.contains(p) else { continue }
            visited.insert(p)
            // Record as the *reverse* edge so path reconstruction works uniformly
            parent[p] = fwdEdge.reversed()
            queue.append(p)
            if p == sink { break bfs }
        }
    }

    guard visited.contains(sink) else { return nil }

    // Reconstruct path from sink back to source
    var path: [Edge] = []
    var cur = sink
    while cur != source {
        guard let e = parent[cur] else { return nil }
        path.append(e)
        cur = e.u
    }
    path.reverse()

    // Bottleneck = minimum residual capacity along the path
    let bottleneck: Double = path.reduce(Double.infinity) { minSoFar, e in
        let cap: Double
        if let attr = net.edgeProperties[e] {
            // Forward arc
            cap = attr.residualCapacity
        } else if let attr = net.edgeProperties[e.reversed()] {
            // Backward (cancellation) arc: residual = existing flow
            cap = attr.flow
        } else {
            cap = 0
        }
        return Swift.min(minSoFar, cap)
    }

    return (path, bottleneck)
}

// MARK: - Dijkstra shortest path (generic, weight-based)

/// Result of a Dijkstra shortest-path search.
public struct ShortestPathResult {
    /// Distance from source to each vertex (`Double.infinity` if unreachable).
    public let distances: [Int: Double]
    /// Predecessor edge on the shortest path to each vertex.
    public let predecessors: [Int: Edge]

    /// Reconstructs the path from `source` to `target` as an ordered vertex array.
    /// Returns `nil` if `target` is unreachable.
    public func path(to target: Int, from source: Int) -> [Int]? {
        guard distances[target] != .infinity, distances[target] != nil else { return nil }
        var result: [Int] = []
        var cur = target
        while cur != source {
            result.append(cur)
            guard let e = predecessors[cur] else { return nil }
            cur = e.u
        }
        result.append(source)
        return result.reversed()
    }
}

// Comparable wrapper so we can use PriorityQueue (which requires Comparable).
struct Entry: Comparable {
    let dist: Double
    let vertex: Int
    public init(dist: Double, vertex: Int) {
        self.dist = dist
        self.vertex = vertex
    }
    static func < (lhs: Entry, rhs: Entry) -> Bool { lhs.dist < rhs.dist }
    static func == (lhs: Entry, rhs: Entry) -> Bool { lhs.dist == rhs.dist && lhs.vertex == rhs.vertex }
}

/// Dijkstra's single-source shortest-path algorithm.
///
/// Works on any `AdjacentGraph<V, W>` where `W` is a `BinaryFloatingPoint`.
/// Edge costs are taken from `edgeProperties`; missing edge properties
/// are treated as cost 0.
///
/// - Parameters:
///   - graph:  The graph to search.
///   - source: Starting vertex index.
/// - Returns:  A `ShortestPathResult` containing distances and predecessors.
public func dijkstra<V, W>(
    graph: AdjacentGraph<V, W>,
    source: Int
) -> ShortestPathResult where W: BinaryFloatingPoint {

    var dist = [Int: Double]()
    var pred = [Int: Edge]()
    var visited = Set<Int>()

    for i in 0..<graph.vertexCount { dist[i] = .infinity }
    dist[source] = 0

    // ascending: true → pop() returns the *smallest* element (min-heap)
    var pq = PriorityQueue<Entry>(ascending: true, startingValues: [Entry(dist: 0.0, vertex: source)])

    while let entry = pq.pop() {
        let u = entry.vertex
        guard !visited.contains(u) else { continue }
        visited.insert(u)

        for v in graph.adjacent(of: u) {
            let e = Edge(u: u, v: v)
            let rawW: W = graph.edgeProperties[e] ?? W(0)
            let w = Double(rawW)
            let newDist = entry.dist + w
            if newDist < (dist[v] ?? .infinity) {
                dist[v] = newDist
                pred[v] = e
                pq.push(Entry(dist: newDist, vertex: v))
            }
        }
    }

    return ShortestPathResult(distances: dist, predecessors: pred)
}

// MARK: - Connectivity helpers

extension AdjacentGraph {

    /// Returns the set of vertex indices reachable from `start` via BFS.
    public func reachable(from start: Int) -> Set<Int> {
        var visited = Set<Int>()
        var queue = [start]
        while !queue.isEmpty {
            let u = queue.removeFirst()
            guard !visited.contains(u) else { continue }
            visited.insert(u)
            for v in adjacent(of: u) where !visited.contains(v) { queue.append(v) }
        }
        return visited
    }

    /// Returns `true` if there is at least one path from `source` to `sink`.
    public func isConnected(from source: Int, to sink: Int) -> Bool {
        reachable(from: source).contains(sink)
    }

    /// Returns all weakly-connected components as arrays of vertex indices.
    public func connectedComponents() -> [[Int]] {
        var unvisited = Set(0..<vertexCount)
        var components: [[Int]] = []
        while let start = unvisited.min() {
            let comp = reachable(from: start)
            components.append(comp.sorted())
            unvisited.subtract(comp)
        }
        return components.sorted { $0.first! < $1.first! }
    }
}
