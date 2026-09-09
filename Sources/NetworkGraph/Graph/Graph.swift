//
//  Graph.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Graph kind

public enum GraphType: Sendable {
    case undirected, directed
}

public enum EdgeUniqueness: Sendable {
    case unique, multi
}

/// Sentinel type used when no edge or vertex property is needed.
public struct NoProperty: Hashable, Codable, Sendable {}

// MARK: - Core protocol

/// The root graph protocol.  All graph representations conform to this.
public protocol Graph {
    /// Type of value stored at each vertex.
    associatedtype Vertex

    /// The kind of graph (directed / undirected).
    var kind: GraphType { get }
}

// MARK: - PropertyGraph

/// A graph that stores an arbitrary property value per-vertex and per-edge.
///
/// - `VertexProperty` is the type stored at each vertex (index-addressed via subscript).
/// - `EdgeProperty`   is the type stored at each edge (Edge-addressed via subscript).
///
/// Both subscripts now expose **read/write** access so callers can update
/// vertex and edge attributes in-place.
public protocol PropertyGraph: Graph {

    /// Type of value associated with each vertex.
    associatedtype VertexProperty

    /// Type of value associated with each edge.
    associatedtype EdgeProperty

    /// Per-edge property store, keyed by `Edge`.
    var edgeProperties: [Edge: EdgeProperty] { get set }

    /// Read/write access to the property at vertex `i`.
    subscript(i: Int) -> VertexProperty { get set }

    /// Read/write access to the property on edge `e`.
    subscript(e: Edge) -> EdgeProperty { get set }

    /// Read/write access to an optional edge property (safe – never crashes).
    subscript(safe e: Edge) -> EdgeProperty? { get set }
}

// MARK: - IncidenceGraph

/// Provides outgoing-edge / adjacency queries.
public protocol IncidenceGraph: Graph {

    /// Number of outgoing edges from `vertex`.
    func degree(vertex: Int) -> Int

    /// Indices of all vertices adjacent (outward) to `vertex`.
    func adjacent(of vertex: Int) -> [Int]

    /// Returns true iff there is an edge from `u` to `v`.
    func isAdjacent(u: Int, v: Int) -> Bool

    /// All edges leaving `vertex` as (source, target) index pairs.
    func adjacentEdges(of vertex: Int) -> [(Int, Int)]

    /// The vertex value at the source end of `edge`.
    func source(edge: Edge) -> Vertex

    /// The vertex value at the target end of `edge`.
    func target(edge: Edge) -> Vertex
}

// MARK: - BidirectionalGraph

/// Extends `IncidenceGraph` with incoming-edge queries.
public protocol BidirectionalGraph: Graph {

    /// Number of incoming edges to `vertex`.
    func indegree(vertex: Int) -> Int

    /// All edges arriving at `vertex` as (source, target) index pairs.
    func inEdges(vertex: Int) -> [(Int, Int)]
}

// MARK: - VertexListGraph

/// Provides random-access vertex enumeration.
public protocol VertexListGraph: Graph {

    /// |V| – total number of vertices.
    var vertexCount: Int { get }

    /// All vertex values in index order.
    var vertices: [Vertex] { get }

    /// The index of a vertex value, or `nil` if not present.
    func index(of vertex: Vertex) -> Int?
}

// MARK: - EdgeListGraph

/// Provides edge enumeration.
public protocol EdgeListGraph: Graph {

    /// |E| – total number of edges.
    var edgeCount: Int { get }

    /// All edges in the graph.
    var edges: [Edge] { get }
}

// MARK: - MutableGraph

/// Allows structural mutations: adding and removing vertices and edges.
public protocol MutableGraph: Graph {

    /// Adds a vertex with value `v`; returns its new index.
    @discardableResult
    mutating func addVertex(v: Vertex) -> Int

    /// Removes the vertex with value `v` and all incident edges.
    mutating func removeVertex(v: Vertex)

    /// Adds a directed edge from index `u` to index `v`.
    /// Returns `true` on success.
    @discardableResult
    mutating func addEdge(u: Int, v: Int) throws -> Bool

    /// Removes the edge from index `u` to index `v`.
    mutating func removeEdge(u: Int, v: Int)

    /// Removes all edges incident to `vertex`.
    mutating func removeAllAdjacentEdges(of vertex: Int)
}

// MARK: - NetworkFlowGraph

/// A graph purpose-built for modelling network flows (max-flow, min-cost flow,
/// supply/demand problems, …).
///
/// Implementors expose per-vertex and per-edge flow attributes through a type-safe
/// property protocol so that flow algorithms can be written generically.
public protocol NetworkFlowGraph: Graph
    where Vertex: VertexAttributesProtocol {

    /// Type of edge attribute used by this flow network.
    associatedtype FlowEdgeAttr: EdgeAttributesProtocol

    /// Returns the attributes of the vertex at `index`.
    func vertexAttributes(at index: Int) -> Vertex

    /// Replaces the attributes of the vertex at `index`.
    mutating func setVertexAttributes(_ attrs: Vertex, at index: Int)

    /// Returns the attributes of edge `e`, or `nil` if not present.
    func edgeAttributes(for edge: Edge) -> FlowEdgeAttr?

    /// Sets (or inserts) the attributes of edge `e`.
    mutating func setEdgeAttributes(_ attrs: FlowEdgeAttr, for edge: Edge)

    /// The source (super-source or single source) vertex index.
    var source: Int { get }

    /// The sink (super-sink or single sink) vertex index.
    var sink: Int { get }
}

// MARK: - Import protocols

/// Conformance for reading unweighted edge-list text files.
public protocol UnweightedGraphImport {

    /// Unweighted graph data is imported to an empty graph G which has to be
    /// initialized with the following signature
    ///         graph = AdjacentGraph<Int, NoProperty>()
    /// Vertices are always synthesized to consecutive integers
    ///         v[] = [0, 1, 2, 3, ... V-2, V-1].
    /// It is a user resposibility that the graph properties are consistent with parsed data;
    /// definition of { undirected | directed }.
    ///
    /// Import format:
    /// ```
    /// V        // vertex count
    /// E        // edge count
    /// u v      // edge 1
    /// …
    /// u v      // edge |E|
    /// ```
    mutating func initialize(unweightedGraph content: [[String]])
}

/// Conformance for reading weighted edge-list text files.
public protocol WeightedGraphImport {

    /// Weighted graph data is imported to an empty graph G which has to be
    /// initialized with the following signature
    ///         graph = AdjacentGraph<Int, Numeric>()
    /// Vertices are always synthesized to consecutive integers
    ///         v[] = [0, 1, 2, 3, ... V-2, V-1].
    /// It is a user resposibility that the graph properties are consistent with parsed data;
    /// definition of { undirected | directed } and edge weight must be a suitable numeric.
    ///
    /// Import format:
    /// ```
    /// V        // vertex count
    /// E        // edge count
    /// u v w    // edge 1
    /// …
    /// u v w    // edge |E|
    /// ```
    mutating func initializeGraph(weightedGraph content: [[String]])
}
