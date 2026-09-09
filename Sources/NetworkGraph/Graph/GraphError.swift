//
//  GraphError.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// Errors thrown by NetworkGraph operations.
public enum NetworkGraphError: Swift.Error, CustomStringConvertible {

    /// A vertex index is outside the valid range `[0, graphSize)`.
    case invalidVertex(index: Int, graphSize: Int)

    /// An edge references one or more invalid vertex indices.
    case invalidEdge(u: Int, v: Int)

    /// A graph argument violates a required structural constraint (e.g. parameter bounds).
    case illegalArgument(cause: String)

    /// A required graph property (e.g. connectivity, planarity) is not satisfied.
    case unsatisfiedPrecondition(cause: String)

    /// A graph contains a negative-weight cycle, preventing shortest-path computation.
    case negativeCycle

    /// A vertex coloring could not be produced with the available information.
    case undefinedGraphColor

    public var description: String {
        switch self {
        case .invalidVertex(let index, let size):
            return "Vertex index \(index) is out of range for graph of size \(size)"
        case .invalidEdge(let u, let v):
            return "Edge (\(u), \(v)) references one or more invalid vertex indices"
        case .illegalArgument(let cause):
            return "Illegal argument: \(cause)"
        case .unsatisfiedPrecondition(let cause):
            return "Unsatisfied precondition: \(cause)"
        case .negativeCycle:
            return "Graph contains a negative-weight cycle"
        case .undefinedGraphColor:
            return "Undefined graph color"
        }
    }
}
