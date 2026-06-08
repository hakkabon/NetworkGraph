//
//  Edges.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// A directed edge identified by its source and target vertex indices.
///
/// `Edge` is the fundamental connectivity token used throughout the graph.
/// Edge-level metadata (weight, capacity, label, …) is stored separately in
/// `EdgeAttributes` and accessed through the graph's `edgeAttributes` dictionary
/// or via `AdjacentGraph`'s property-graph subscript.
public struct Edge: Codable, Sendable {

    /// Source vertex index (0-based).
    public var u: Int

    /// Target vertex index (0-based).
    public var v: Int

    /// Creates an edge from `u` to `v`.
    public init(u: Int, v: Int) {
        self.u = u
        self.v = v
    }

    /// Returns the reverse of this edge.
    public func reversed() -> Edge {
        return Edge(u: v, v: u)
    }
}

// MARK: - Equatable

extension Edge: Equatable {
    public static func == (lhs: Edge, rhs: Edge) -> Bool {
        return lhs.u == rhs.u && lhs.v == rhs.v
    }
}

// MARK: - Hashable

extension Edge: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(u)
        hasher.combine(v)
    }
}

// MARK: - CustomStringConvertible

extension Edge: CustomStringConvertible {
    public var description: String { "\(u) → \(v)" }
}
