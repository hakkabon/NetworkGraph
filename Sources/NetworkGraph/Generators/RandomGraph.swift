//
//  RandomGraph.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public enum RandomGraph {

    /// Returns a random graph containing `V` vertices and `E` edges.
    ///
    /// - Parameters:
    ///   - V: the number of vertices
    ///   - E: the number of edges
    /// - Returns: a random simple graph on V vertices, containing a total of E edges
    /// - Throws: IllegalArgument if no such simple graph exists
    public static func build(vertex V: Int, edge E: Int) throws -> AdjacentGraph<Int,NoProperty> {
        guard E < V*(V-1)/2 else {
            throw NetworkGraphError.illegalArgument(cause: "Too many edges")
        }
        guard E > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Too few edges")
        }
        let vertices = Array(0..<V)
        var g = AdjacentGraph<Int,NoProperty>(vertices: vertices)
        //for i in 0..<V { g.addVertex(v: i) }
        var set = Set<Edge>()
        while g.edgeCount < E {
            let u = Int.random(in: 0..<V)
            let v = Int.random(in: 0..<V)
            let e = Edge(u: u, v: v)
            if u != v && !set.contains(e) {
                set.insert(e)
                _ = g.addEdge(u: e.u, v: e.v)
            }
        }
        return g
    }
    
    /// Returns an Erdos Renyi random graph containing `V` vertices and `edges` edges.
    ///
    /// - Parameters:
    ///   - V: the number of vertices
    ///   - p: the probability that the graph contains an edge with one endpoint in either side
    /// - Returns: a random simple graph on `V` vertices, containing a total of `E` edges
    /// - Throws: IllegalArgument if no such graph exists
    public static func build(vertex V: Int, probability p: Float) throws -> AdjacentGraph<Int,NoProperty> {
        let vertices = Array(0..<V)
        var g = AdjacentGraph<Int,NoProperty>(vertices: vertices)
        for u in 0 ..< V {
            for v in (u+1) ..< V {
                if try bernoulli(p) {
                    _ = g.addEdge(u: u, v: v)
                }
            }
        }
        return g
    }
}

public enum BipartiteRandomGraph {

    /// Returns a bipartite random graph containing `V` vertices and `edges` edges.
    ///
    /// - Parameters:
    ///   - V: the number of vertices
    ///   - edges: the number of vertices
    /// - Returns: a random simple graph on {@code V} vertices, containing a total
    ///     of {@code E} edges
    /// - Throws: IllegalArgument if no such simple graph exists
    public static func build(partition V1: Int, partition V2: Int, edge E: Int) throws -> AdjacentGraph<Int,NoProperty> {
        guard E < V1*V2 else {
            throw NetworkGraphError.illegalArgument(cause: "Too many edges")
        }
        guard E > 0 else {
            throw NetworkGraphError.illegalArgument(cause: "Too few edges")
        }
        let vertices = Array(0..<V1+V2)
        var g = AdjacentGraph<Int,NoProperty>(vertices: vertices)
        var set = Set<Edge>()
        while g.edgeCount < E {
            let i = Int.random(in: 0 ..< V1)
            let j = Int.random(in: V1 ..< V2)
            let e = Edge(u: i, v: j)
            if !set.contains(e) {
                set.insert(e)
                _ = g.addEdge(u: e.u, v: e.v)
            }
        }
        return g
    }

    /// Returns a bipartite random graph containing `V` vertices and `edges` edges.
    ///
    /// - Parameters:
    ///   - V: the number of vertices
    ///   - - p: the probability that the graph contains an edge with one endpoint in either side
    /// - Returns: a random simple graph on {@code V} vertices, containing a total
    ///     of {@code E} edges
    /// - Throws: IllegalArgument if no such simple graph exists
    public static func build(firstPartitionVertex V1: Int, vertex V2: Int, probability p: Float) throws -> AdjacentGraph<Int,NoProperty> {
        let vertices = Array(0..<V1+V2)
        var g = AdjacentGraph<Int,NoProperty>(vertices: vertices)
        for i in 0 ..< V1 {
            for j in 0 ..< V2 {
                if try bernoulli(p) {
                    _ = g.addEdge(u: i, v: j)
                }
            }
        }
        return g
    }
}
