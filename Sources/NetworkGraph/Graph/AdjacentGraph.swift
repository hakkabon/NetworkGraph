//
//  AdjacentGraph.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// An adjacency-list graph that conforms to the full `Graph` protocol suite.
///
/// `V` — the type stored at each vertex (must be `Hashable & Codable`).
/// `W` — the type stored at each edge  (must be `Hashable & Codable`).
///
/// Both `V` and `W` are fully accessible through read/write subscripts, making
/// it straightforward to update vertex or edge data in place:
///
/// ```swift
/// var g = AdjacentGraph<String, WeightedEdge>(vertices: ["A","B","C"])
/// _ = g.addEdge(u: 0, v: 1)
/// g[Edge(u: 0, v: 1)] = WeightedEdge(weight: 3.5)
/// g[0] = "Alpha"
/// ```
public struct AdjacentGraph<V: Hashable & Codable, W: Hashable & Codable> {

    // MARK: Type aliases

    public typealias Vertex        = V
    public typealias VertexProperty = V
    public typealias EdgeProperty  = W

    // MARK: Stored properties

    private var graphType: GraphType = .undirected

    /// Vertex value array (index == vertex identifier).
    public var vertex: [V] = []

    /// Outgoing adjacency lists.
    private var adjacent: [[Int]] = []

    /// Incoming adjacency lists (kept in sync for bidirectional queries).
    private var incoming: [[Int]] = []

    /// Per-edge property store, keyed by `Edge`.
    public var edgeProperties: [Edge: W] = [:]

    // MARK: - Initialisers

    /// Creates an empty graph.
    public init(kind: GraphType = .directed) {
        graphType = kind
    }

    /// Creates a graph containing only the given vertices (no edges).
    public init(vertices: [V], kind: GraphType = .directed) {
        graphType = kind
        for v in vertices { _ = addVertex(v: v) }
        assert(vertexCount == vertices.count)
        assert(vertexCount == adjacent.count)
    }

    /// Creates a graph from a vertex array and a complete adjacency-list
    /// (the adjacency list index matches the vertex array index).
    public init(vertices: [V], adacency: [[Int]], kind: GraphType = .directed) {
        guard vertices.count == adacency.count else { fatalError("vertices / adjacency count mismatch") }
        graphType = kind
        for (i, v) in vertices.enumerated() {
            self.vertex.append(v)
            self.adjacent.append(adacency[i])
            self.incoming.append([])
        }
        // Rebuild incoming lists
        for u in 0..<vertex.count {
            for v in adjacent[u] { incoming[v].append(u) }
        }
        assert(edgeCount == adacency.joined().count)
        assert(vertexCount == vertices.count)
    }

    /// Creates a graph from a vertex array and an `[Edge]` list.
    public init(vertices: [V], edges: [Edge], kind: GraphType = .directed) {
        graphType = kind
        for v in vertices { _ = addVertex(v: v) }
        for e in edges { _ = addEdge(u: e.u, v: e.v) }
        assert(edgeCount == edges.count)
        assert(vertexCount == vertices.count)
    }

    /// Creates a graph from a vertex array and a `[(Int,Int)]` tuple list.
    public init(vertices: [V], edges: [(Int, Int)], kind: GraphType = .directed) {
        graphType = kind
        for v in vertices { _ = addVertex(v: v) }
        for (u, v) in edges { _ = addEdge(u: u, v: v) }
        assert(vertexCount == vertices.count)
    }

    /// Creates an unweighted graph from `(String,String)` edge tuples.
    /// Vertices are derived implicitly from the endpoint names.
    public init(_ edges: [(String, String)], kind: GraphType = .directed) {
        graphType = kind
        var indexMap: [V: Int] = [:]
        var counter = Counter()

        var rawEdges: [(Int, Int)] = []
        for (us, vs) in edges {
            let u: V = convert(string: us, to: V.self)
            let v: V = convert(string: vs, to: V.self)
            if indexMap[u] == nil { indexMap[u] = counter(); vertex.append(u); adjacent.append([]); incoming.append([]) }
            if indexMap[v] == nil { indexMap[v] = counter(); vertex.append(v); adjacent.append([]); incoming.append([]) }
            rawEdges.append((indexMap[u]!, indexMap[v]!))
        }
        for (u, v) in rawEdges { _ = addEdge(u: u, v: v) }
        assert(vertexCount == indexMap.count)
        assert(vertexCount == adjacent.count)
    }

    /// Creates a weighted graph from `(String,String,String)` edge tuples.
    public init(_ edges: [(String, String, String)], kind: GraphType = .directed) {
        graphType = kind
        var indexMap: [V: Int] = [:]
        var counter = Counter()

        for (us, vs, ws) in edges {
            let u: V = convert(string: us, to: V.self)
            let v: V = convert(string: vs, to: V.self)
            let w: W = convert(string: ws, to: W.self)
            if indexMap[u] == nil { indexMap[u] = counter(); vertex.append(u); adjacent.append([]); incoming.append([]) }
            if indexMap[v] == nil { indexMap[v] = counter(); vertex.append(v); adjacent.append([]); incoming.append([]) }
            let i = indexMap[u]!, j = indexMap[v]!
            adjacent[i].append(j)
            incoming[j].append(i)
            edgeProperties[Edge(u: i, v: j)] = w
            if graphType == .undirected && i != j {
                adjacent[j].append(i)
                incoming[i].append(j)
                edgeProperties[Edge(u: j, v: i)] = w
            }
        }
        assert(vertexCount == indexMap.count)
        assert(vertexCount == adjacent.count)
    }
}

// MARK: - Graph

extension AdjacentGraph: Graph {
    public var kind: GraphType { graphType }
}

// MARK: - PropertyGraph

extension AdjacentGraph: PropertyGraph {

    /// Read/write the vertex value at `i`.
    public subscript(i: Int) -> V {
        get { vertex[i] }
        set { vertex[i] = newValue }
    }

    /// Read/write the edge property for edge `e` (force-unwraps; edge must exist).
    public subscript(e: Edge) -> W {
        get { edgeProperties[e]! }
        set { edgeProperties[e] = newValue }
    }

    /// Safe read/write: returns `nil` if edge `e` has no property set.
    public subscript(safe e: Edge) -> W? {
        get { edgeProperties[e] }
        set { edgeProperties[e] = newValue }
    }
}

// MARK: - VertexListGraph

extension AdjacentGraph: VertexListGraph {

    public var vertices: [V] { vertex }
    public var vertexCount: Int { vertex.count }

    public func index(of vertex: V) -> Int? {
        self.vertex.firstIndex(where: { $0 == vertex })
    }
}

// MARK: - EdgeListGraph

extension AdjacentGraph: EdgeListGraph {

    public var edgeCount: Int { adjacent.joined().count }

    /// All edges in the graph as `Edge` values.
    public var edges: [Edge] {
        var result: [Edge] = []
        for u in 0..<adjacent.count {
            for v in adjacent[u] { result.append(Edge(u: u, v: v)) }
        }
        return result
    }
}

// MARK: - IncidenceGraph

extension AdjacentGraph: IncidenceGraph {

    public func degree(vertex: Int) -> Int { adjacent[vertex].count }

    public func adjacent(of vertex: Int) -> [Int] { adjacent[vertex] }

    public func isAdjacent(u: Int, v: Int) -> Bool {
        guard u >= 0, u < adjacent.count, v >= 0, v < adjacent.count else { return false }
        return adjacent[u].contains(v)
    }

    public func adjacentEdges(of v: Int) -> [(Int, Int)] {
        adjacent[v].map { (v, $0) }
    }

    public func source(edge: Edge) -> V { vertex[edge.u] }
    public func target(edge: Edge) -> V { vertex[edge.v] }
}

// MARK: - BidirectionalGraph

extension AdjacentGraph: BidirectionalGraph {

    /// Number of incoming edges to `vertex`.
    public func indegree(vertex: Int) -> Int {
        guard vertex >= 0, vertex < incoming.count else { return 0 }
        return incoming[vertex].count
    }

    /// All edges arriving at `vertex`.
    public func inEdges(vertex: Int) -> [(Int, Int)] {
        guard vertex >= 0, vertex < incoming.count else { return [] }
        return incoming[vertex].map { ($0, vertex) }
    }
}

// MARK: - MutableGraph

extension AdjacentGraph: MutableGraph {

    @discardableResult
    public mutating func addVertex(v: V) -> Int {
        vertex.append(v)
        adjacent.append([])
        incoming.append([])
        return vertex.count - 1
    }

    /// Removes vertex `v`, its stored value, all outgoing/incoming edges,
    /// and re-indexes all remaining edges so the index space stays contiguous.
    public mutating func removeVertex(v: V) {
        guard let idx = index(of: v) else { return }

        // Remove all edges incident on idx
        let outgoing = adjacent[idx]
        for j in outgoing {
            if let pos = incoming[j].firstIndex(of: idx) { incoming[j].remove(at: pos) }
            edgeProperties.removeValue(forKey: Edge(u: idx, v: j))
        }
        for i in incoming[idx] {
            if let pos = adjacent[i].firstIndex(of: idx) { adjacent[i].remove(at: pos) }
            edgeProperties.removeValue(forKey: Edge(u: i, v: idx))
        }

        vertex.remove(at: idx)
        adjacent.remove(at: idx)
        incoming.remove(at: idx)

        // Re-map all index references > idx downward by 1
        func shift(_ i: Int) -> Int { i > idx ? i - 1 : i }

        adjacent  = adjacent.map  { $0.map(shift) }
        incoming  = incoming.map  { $0.map(shift) }

        let oldProps = edgeProperties
        edgeProperties = [:]
        for (e, w) in oldProps {
            let newEdge = Edge(u: shift(e.u), v: shift(e.v))
            edgeProperties[newEdge] = w
        }
    }

    @discardableResult
    public mutating func addEdge(u: Int, v: Int) -> Bool {
        guard u >= 0, u < adjacent.count else { fatalError("invalid source vertex \(u)") }
        guard v >= 0, v < adjacent.count else { fatalError("invalid target vertex \(v)") }
        adjacent[u].append(v)
        incoming[v].append(u)
        if graphType == .undirected && u != v {
            adjacent[v].append(u)
            incoming[u].append(v)
        }
        return true
    }

    public mutating func removeEdge(u: Int, v: Int) {
        guard u >= 0, u < adjacent.count else { return }
        guard v >= 0, v < adjacent.count else { return }
        if let pos = adjacent[u].firstIndex(of: v) { adjacent[u].remove(at: pos) }
        if let pos = incoming[v].firstIndex(of: u) { incoming[v].remove(at: pos) }
        edgeProperties.removeValue(forKey: Edge(u: u, v: v))
        if graphType == .undirected && u != v {
            if let pos = adjacent[v].firstIndex(of: u) { adjacent[v].remove(at: pos) }
            if let pos = incoming[u].firstIndex(of: v) { incoming[u].remove(at: pos) }
            edgeProperties.removeValue(forKey: Edge(u: v, v: u))
        }
    }

    public mutating func removeAllAdjacentEdges(of v: Int) {
        guard v >= 0, v < adjacent.count else { return }
        for j in adjacent[v] {
            if let pos = incoming[j].firstIndex(of: v) { incoming[j].remove(at: pos) }
            edgeProperties.removeValue(forKey: Edge(u: v, v: j))
        }
        adjacent[v] = []
    }
}

// MARK: - Convenience vertex/edge attribute API

extension AdjacentGraph {

    /// Returns the vertex value at `index`.
    public func vertexValue(at index: Int) -> V {
        vertex[index]
    }

    /// Updates the vertex value at `index`.
    public mutating func setVertexValue(_ value: V, at index: Int) {
        vertex[index] = value
    }

    /// Returns the edge property for `edge`, or `nil` if none is stored.
    public func edgeProperty(for edge: Edge) -> W? {
        edgeProperties[edge]
    }

    /// Sets the edge property for `edge`.
    public mutating func setEdgeProperty(_ property: W, for edge: Edge) {
        edgeProperties[edge] = property
    }

    /// Applies `transform` to every vertex value in place.
    public mutating func mapVertices(_ transform: (V) -> V) {
        vertex = vertex.map(transform)
    }

    /// Applies `transform` to every edge property value in place.
    public mutating func mapEdges(_ transform: (W) -> W) {
        for key in edgeProperties.keys {
            edgeProperties[key] = transform(edgeProperties[key]!)
        }
    }
}

// MARK: - Collection

extension AdjacentGraph: Collection {
    public var startIndex: Int { 0 }
    public var endIndex: Int   { vertex.count }
    public func index(after i: Int) -> Int { i + 1 }
}

// MARK: - CustomStringConvertible

extension AdjacentGraph: CustomStringConvertible {
    public var description: String {
        var s = "AdjacentGraph (\(kind), |V|=\(vertexCount), |E|=\(edgeCount))\n"
        for i in 0..<vertex.count {
            s += "  [\(i)] \(vertex[i])  →  \(adjacent[i])\n"
        }
        if !edgeProperties.isEmpty {
            s += "  Edge properties:\n"
            for (e, w) in edgeProperties.sorted(by: { ($0.key.u, $0.key.v) < ($1.key.u, $1.key.v) }) {
                s += "    \(e)  =  \(w)\n"
            }
        }
        return s
    }
}

// MARK: - Import conformance

extension AdjacentGraph: UnweightedGraphImport where V == Int {
    public mutating func initialize(unweightedGraph content: [[String]]) {
        guard content.count > 3 else { return }
        guard let nVertices = Int(content[0].joined()) else { fatalError("bad vertex count") }
        self.vertex   = Array(0..<nVertices)
        self.adjacent = Array(repeating: [], count: nVertices)
        self.incoming = Array(repeating: [], count: nVertices)
        guard Int(content[1].joined()) != nil else { fatalError("bad edge count") }
        let data: [(String, String)] = content.dropFirst(2).map { $0.splat2() }
        for (s, t) in data {
            let u = convert(string: s, to: V.self)
            let v = convert(string: t, to: V.self)
            assert(u >= 0 && u < nVertices)
            assert(v >= 0 && v < nVertices)
            adjacent[u].append(v)
            incoming[v].append(u)
        }
        assert(vertexCount == nVertices)
    }
}

extension AdjacentGraph: WeightedGraphImport where V == Int, W: Numeric {
    public mutating func initializeGraph(weightedGraph content: [[String]]) {
        guard content.count > 3 else { return }
        guard let nVertices = Int(content[0].joined()) else { fatalError("bad vertex count") }
        self.vertex   = Array(0..<nVertices)
        self.adjacent = Array(repeating: [], count: nVertices)
        self.incoming = Array(repeating: [], count: nVertices)
        guard Int(content[1].joined()) != nil else { fatalError("bad edge count") }
        let data: [(String, String, String)] = content.dropFirst(2).map { $0.splat3() }
        for (r, s, t) in data {
            let u = convert(string: r, to: V.self)
            let v = convert(string: s, to: V.self)
            let w: W = convert(string: t, to: W.self)
            assert(u >= 0 && u < nVertices)
            assert(v >= 0 && v < nVertices)
            adjacent[u].append(v)
            incoming[v].append(u)
            edgeProperties[Edge(u: u, v: v)] = w
        }
        assert(vertexCount == nVertices)
    }
}
