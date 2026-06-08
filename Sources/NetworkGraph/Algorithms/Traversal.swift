//
//  Traversal.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2021/05/28.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public func depthFirstSearch<G: IncidenceGraph & VertexListGraph, C: ReadWritePropertyMap, V: Visitor>
    (graph: G, startVertex: Int, colorMap: inout C, visitor: V) where
    V.Vertex == Int,
    G.Vertex == V.Vertex,
    C.Key    == G.Vertex,
    C.Value  == VertexColor
{
    for v in graph.adjacent(of: startVertex) {
        switch colorMap.get(key: v) {
        case .white:
            colorMap.put(key: v, value: .gray)
            depthFirstSearch(graph: graph, startVertex: v, colorMap: &colorMap, visitor: visitor)
        case .gray: continue
        case .black: continue
        }
    }
    visitor.visit(vertex: startVertex)
    colorMap.put(key: startVertex, value: .black)
}

public func breadthFirstSearch<G: IncidenceGraph & VertexListGraph, C: ReadWritePropertyMap, V: Visitor>
    (graph: G, startVertex: Int, colorMap: inout C, visitor: V) where
    V.Vertex == Int,
    G.Vertex == V.Vertex,
    C.Key    == G.Vertex,
    C.Value  == VertexColor
{
    guard graph.vertexCount > 0 else { return }
    
    for vertex in graph.vertices {
        colorMap.put(key: vertex, value: .white)
    }
    
    var queue = Array<G.Vertex>()
    colorMap.put(key: startVertex, value: .gray)
    visitor.visit(vertex: startVertex)
    queue.append(startVertex)
    
    while !queue.isEmpty {
        let u = queue.removeFirst()
        for v in graph.adjacent(of: u) {
            switch colorMap.get(key: v) {
            case .white:
                colorMap.put(key: v, value: .gray)
                visitor.visit(vertex: v)
                queue.append(v)
            case .gray: continue
            case .black: continue
            }
        }
        colorMap.put(key: u, value: .black)
    }
}
