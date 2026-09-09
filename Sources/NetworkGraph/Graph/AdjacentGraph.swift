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
/// _ = try g.addEdge(u: 0, v: 1)
/// g[Edge(u: 0, v: 1)] = WeightedEdge(weight: 3.5)
/// g[0] = "Alpha"
/// ```
public struct AdjacentGraph<V: Hashable & Codable & Sendable, W: Hashable & Codable & Sendable>: Sendable {

    // MARK: Type aliases

    public typealias Vertex        = V
    public typealias VertexProperty = V
    public typealias EdgeProperty  = W

    // MARK: Stored properties

    private var graphType: GraphType = .undirected

    /// Vertex value array (index == vertex identifier).
    public var vertex: [V] = []

    /// Fast O(1) reverse lookup: vertex value to its internal index.
    private var vertexIndex: [V: Int] = [:]

    /// Outgoing adjacency lists.
    private var adjacent: [[Int]] = []

    /// Outgoing adjacency sets for O(1) `isAdjacent` checks.
    private var adjacentSet: [Set<Int>] = []

    /// Incoming adjacency lists (kept in sync for bidirectional queries).
    private var incoming: [[Int]] = []

    /// Cached total edge count for O(1) `edgeCount`.
    private var _edgeCount: Int = 0

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
    public init(vertices: [V], adjacency: [[Int]], kind: GraphType = .directed) {
        guard vertices.count == adjacency.count else { fatalError("vertices / adjacency count mismatch") }
        graphType = kind
        for (i, v) in vertices.enumerated() {
            self.vertex.append(v)
            self.vertexIndex[v] = i
            self.adjacent.append(adjacency[i])
            self.adjacentSet.append(Set(adjacency[i]))
            self.incoming.append([])
        }
        // Rebuild incoming lists
        for u in 0..<vertex.count {
            for v in adjacent[u] { incoming[v].append(u) }
        }
        self._edgeCount = adjacency.joined().count
        assert(edgeCount == adjacency.joined().count)
        assert(vertexCount == vertices.count)
    }

    /// Deprecated typo version of `init(vertices:adjacency:kind:)`.
    @available(*, deprecated, renamed: "init(vertices:adjacency:kind:)")
    public init(vertices: [V], adacency: [[Int]], kind: GraphType = .directed) {
        self.init(vertices: vertices, adjacency: adacency, kind: kind)
    }

    /// Creates a graph from a vertex array and an `[Edge]` list.
    public init(vertices: [V], edges: [Edge], kind: GraphType = .directed) {
        graphType = kind
        for v in vertices { _ = addVertex(v: v) }
        for e in edges { _addEdge(u: e.u, v: e.v) }
        assert(edgeCount == edges.count)
        assert(vertexCount == vertices.count)
    }

    /// Creates a graph from a vertex array and a `[(Int,Int)]` tuple list.
    public init(vertices: [V], edges: [(Int, Int)], kind: GraphType = .directed) {
        graphType = kind
        for v in vertices { _ = addVertex(v: v) }
        for (u, v) in edges { _addEdge(u: u, v: v) }
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
            if indexMap[u] == nil {
                let idx = counter()
                indexMap[u] = idx
                vertex.append(u)
                vertexIndex[u] = idx
                adjacent.append([])
                adjacentSet.append([])
                incoming.append([])
            }
            if indexMap[v] == nil {
                let idx = counter()
                indexMap[v] = idx
                vertex.append(v)
                vertexIndex[v] = idx
                adjacent.append([])
                adjacentSet.append([])
                incoming.append([])
            }
            rawEdges.append((indexMap[u]!, indexMap[v]!))
        }
        for (u, v) in rawEdges { _addEdge(u: u, v: v) }
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
            if indexMap[u] == nil {
                let idx = counter()
                indexMap[u] = idx
                vertex.append(u)
                vertexIndex[u] = idx
                adjacent.append([])
                adjacentSet.append([])
                incoming.append([])
            }
            if indexMap[v] == nil {
                let idx = counter()
                indexMap[v] = idx
                vertex.append(v)
                vertexIndex[v] = idx
                adjacent.append([])
                adjacentSet.append([])
                incoming.append([])
            }
            let i = indexMap[u]!, j = indexMap[v]!
            _addEdge(u: i, v: j)
            edgeProperties[Edge(u: i, v: j)] = w
            if graphType == .undirected && i != j {
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
        set {
            let old = vertex[i]
            vertexIndex.removeValue(forKey: old)
            vertex[i] = newValue
            vertexIndex[newValue] = i
        }
    }

    /// Read/write the edge property for edge `e` (force-unwraps; edge must exist).
    public subscript(e: Edge) -> W {
        get { (edgeProperties[e] ?? (graphType == .undirected ? edgeProperties[e.reversed()] : nil))! }
        set {
            edgeProperties[e] = newValue
            if graphType == .undirected && e.u != e.v {
                edgeProperties[e.reversed()] = newValue
            }
        }
    }

    /// Safe read/write: returns `nil` if edge `e` has no property set.
    public subscript(safe e: Edge) -> W? {
        get { edgeProperties[e] ?? (graphType == .undirected ? edgeProperties[e.reversed()] : nil) }
        set {
            edgeProperties[e] = newValue
            if graphType == .undirected && e.u != e.v {
                edgeProperties[e.reversed()] = newValue
            }
        }
    }
}

// MARK: - VertexListGraph

extension AdjacentGraph: VertexListGraph {

    public var vertices: [V] { vertex }
    public var vertexCount: Int { vertex.count }

    public func index(of vertex: V) -> Int? {
        vertexIndex[vertex]
    }
}

// MARK: - EdgeListGraph

extension AdjacentGraph: EdgeListGraph {

    public var edgeCount: Int { _edgeCount }

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
        guard u >= 0, u < adjacentSet.count, v >= 0, v < adjacentSet.count else { return false }
        return adjacentSet[u].contains(v)
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
        let idx = vertex.count
        vertex.append(v)
        vertexIndex[v] = idx
        adjacent.append([])
        adjacentSet.append([])
        incoming.append([])
        return idx
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
            edgeProperties.removeValue(forKey: Edge(u: j, v: idx))
            _edgeCount -= 1
        }
        for i in incoming[idx] {
            if let pos = adjacent[i].firstIndex(of: idx) {
                adjacent[i].remove(at: pos)
                adjacentSet[i].remove(idx)
                _edgeCount -= 1
            }
            edgeProperties.removeValue(forKey: Edge(u: i, v: idx))
            edgeProperties.removeValue(forKey: Edge(u: idx, v: i))
        }

        vertex.remove(at: idx)
        adjacent.remove(at: idx)
        adjacentSet.remove(at: idx)
        incoming.remove(at: idx)

        // Re-map all index references > idx downward by 1
        func shift(_ i: Int) -> Int { i > idx ? i - 1 : i }

        adjacent  = adjacent.map  { $0.map(shift) }
        adjacentSet = adjacentSet.map { Set($0.map(shift)) }
        incoming  = incoming.map  { $0.map(shift) }

        vertexIndex = [:]
        for (i, vert) in vertex.enumerated() {
            vertexIndex[vert] = i
        }

        let oldProps = edgeProperties
        edgeProperties = [:]
        for (e, w) in oldProps {
            let newEdge = Edge(u: shift(e.u), v: shift(e.v))
            edgeProperties[newEdge] = w
        }
    }

    @discardableResult
    public mutating func addEdge(u: Int, v: Int) throws -> Bool {
        guard u >= 0, u < adjacent.count else {
            throw NetworkGraphError.invalidVertex(index: u, graphSize: adjacent.count)
        }
        guard v >= 0, v < adjacent.count else {
            throw NetworkGraphError.invalidVertex(index: v, graphSize: adjacent.count)
        }
        return _addEdge(u: u, v: v)
    }

    /// Fast path for adding edges when vertex indices are known to be valid.
    @discardableResult
    public mutating func _addEdge(u: Int, v: Int) -> Bool {
        adjacent[u].append(v)
        adjacentSet[u].insert(v)
        incoming[v].append(u)
        _edgeCount += 1
        if graphType == .undirected && u != v {
            adjacent[v].append(u)
            adjacentSet[v].insert(u)
            incoming[u].append(v)
            _edgeCount += 1
        }
        return true
    }

    public mutating func removeEdge(u: Int, v: Int) {
        guard u >= 0, u < adjacent.count else { return }
        guard v >= 0, v < adjacent.count else { return }
        if let pos = adjacent[u].firstIndex(of: v) {
            adjacent[u].remove(at: pos)
            _edgeCount -= 1
        }
        adjacentSet[u].remove(v)
        if let pos = incoming[v].firstIndex(of: u) { incoming[v].remove(at: pos) }
        edgeProperties.removeValue(forKey: Edge(u: u, v: v))
        edgeProperties.removeValue(forKey: Edge(u: v, v: u))
        if graphType == .undirected && u != v {
            if let pos = adjacent[v].firstIndex(of: u) {
                adjacent[v].remove(at: pos)
                _edgeCount -= 1
            }
            adjacentSet[v].remove(u)
            if let pos = incoming[u].firstIndex(of: v) { incoming[u].remove(at: pos) }
        }
    }

    public mutating func removeAllAdjacentEdges(of v: Int) {
        guard v >= 0, v < adjacent.count else { return }
        for j in adjacent[v] {
            if let pos = incoming[j].firstIndex(of: v) { incoming[j].remove(at: pos) }
            edgeProperties.removeValue(forKey: Edge(u: v, v: j))
            edgeProperties.removeValue(forKey: Edge(u: j, v: v))
            _edgeCount -= 1
            if graphType == .undirected && v != j {
                if let pos = adjacent[j].firstIndex(of: v) {
                    adjacent[j].remove(at: pos)
                    _edgeCount -= 1
                }
                adjacentSet[j].remove(v)
            }
        }
        adjacent[v] = []
        adjacentSet[v] = []
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
        let old = vertex[index]
        vertexIndex.removeValue(forKey: old)
        vertex[index] = value
        vertexIndex[value] = index
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
        vertexIndex = [:]
        for (i, v) in vertex.enumerated() {
            vertexIndex[v] = i
        }
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
        self.vertex      = Array(0..<nVertices)
        self.vertexIndex = Dictionary(uniqueKeysWithValues: (0..<nVertices).map { ($0, $0) })
        self.adjacent    = Array(repeating: [], count: nVertices)
        self.adjacentSet = Array(repeating: [], count: nVertices)
        self.incoming    = Array(repeating: [], count: nVertices)
        self._edgeCount  = 0
        guard Int(content[1].joined()) != nil else { fatalError("bad edge count") }
        let data: [(String, String)] = content.dropFirst(2).map { $0.splat2() }
        for (s, t) in data {
            let u = convert(string: s, to: V.self)
            let v = convert(string: t, to: V.self)
            assert(u >= 0 && u < nVertices)
            assert(v >= 0 && v < nVertices)
            _addEdge(u: u, v: v)
        }
        assert(vertexCount == nVertices)
    }
}

extension AdjacentGraph: WeightedGraphImport where V == Int, W: Numeric {
    public mutating func initializeGraph(weightedGraph content: [[String]]) {
        guard content.count > 3 else { return }
        guard let nVertices = Int(content[0].joined()) else { fatalError("bad vertex count") }
        self.vertex      = Array(0..<nVertices)
        self.vertexIndex = Dictionary(uniqueKeysWithValues: (0..<nVertices).map { ($0, $0) })
        self.adjacent    = Array(repeating: [], count: nVertices)
        self.adjacentSet = Array(repeating: [], count: nVertices)
        self.incoming    = Array(repeating: [], count: nVertices)
        self._edgeCount  = 0
        guard Int(content[1].joined()) != nil else { fatalError("bad edge count") }
        let data: [(String, String, String)] = content.dropFirst(2).map { $0.splat3() }
        for (r, s, t) in data {
            let u = convert(string: r, to: V.self)
            let v = convert(string: s, to: V.self)
            let w: W = convert(string: t, to: W.self)
            assert(u >= 0 && u < nVertices)
            assert(v >= 0 && v < nVertices)
            _addEdge(u: u, v: v)
            edgeProperties[Edge(u: u, v: v)] = w
        }
        assert(vertexCount == nVertices)
    }
}
