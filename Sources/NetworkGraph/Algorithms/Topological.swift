//
//  Topological.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2021/05/28.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// skipped & VertexListGraph
public func topologicalSort<G: IncidenceGraph & VertexListGraph> (graph: G) -> [G.Vertex] where
    G.Vertex == Int,
    G.Vertex: Hashable
{
    guard graph.vertexCount > 0 else { return [] }
    
    // find the root vertices
    var roots = Set<G.Vertex>(graph.vertices)
    for u in graph.vertices {
        for v in graph.adjacent(of: u) {
            if roots.contains(v) {
                roots.remove(v)
            }
        }
    }
    assert(!roots.isEmpty, "not a DAG")
    
    // important, we must initialize the color map outside of DFS so that we can share
    // it amongst each DFS call for each root. Boost Graph Library solved this by having
    // two variants of DFS, depth_first_search and depth_first_visit, which did and did not
    // initialize the color map, respectively.
    var colorMap = PropertyMap<G.Vertex, VertexColor>()
    for u in graph.vertices {
        colorMap.put(key: u, value: .white)
    }
    
    // walk the graph
    let visitor = AccumulatorVisitor<G.Vertex>()
    for root in roots {
        depthFirstSearch(graph: graph, startVertex: root, colorMap: &colorMap, visitor: visitor)
    }
    return visitor.accumulator
}
