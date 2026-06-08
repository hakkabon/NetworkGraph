//
//  GraphTraversal.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public enum VertexColor {
    case white, gray, black
}

public protocol Visitor {
    associatedtype Vertex
    func visit(vertex: Vertex)
}

public class PrintVisitor: Visitor {
    public init() {}
    public func visit(vertex: Int) {
        print("vertex: '\(vertex)'")
    }
}

/// Collects visited vertices in order for inspection or testing.
public class AccumulatorVisitor<Vertex>: Visitor {
    public private(set) var accumulator = [Vertex]()
    public init() {}
    public func visit(vertex: Vertex) {
        accumulator.append(vertex)
    }
}
