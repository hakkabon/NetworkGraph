// EdgeProperties.swift
// NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Edge Property Protocols
#if false
/// An edge that carries a single numeric weight.
public protocol WeightedEdge {
    associatedtype Weight: Numeric & Comparable & Codable
    var weight: Weight { get }
}

/// An edge with a read/write weight.
public protocol MutableWeightedEdge: WeightedEdge {
    var weight: Weight { get set }
}

/// An edge that carries an arbitrary metadata dictionary.
public protocol AnnotatedEdge {
    var attributes: [String: String] { get }
}

/// An edge with read/write access to its metadata dictionary.
public protocol MutableAnnotatedEdge: AnnotatedEdge {
    var attributes: [String: String] { get set }
}

/// An edge that participates in network-flow modelling.
/// Provides capacity, current flow, lower bound, and cost per unit of flow.
public protocol FlowEdge {
    /// Maximum flow that can be routed along this edge.
    var capacity: Double { get set }
    /// Current flow assigned to this edge (must satisfy 0 ≤ flow ≤ capacity).
    var flow: Double { get set }
    /// Minimum required flow along this edge (default 0).
    var lowerBound: Double { get set }
    /// Cost per unit of flow (for min-cost flow problems).
    var cost: Double { get set }
    /// Remaining capacity: capacity − flow.
    var residualCapacity: Double { get }
    /// Whether additional flow can be pushed along this edge.
    var isSaturated: Bool { get }
}
#endif

// MARK: - Concrete Edge Property Types

/// A plain numeric weight on an edge.
public struct WeightedEdgeProperty<W: Numeric & Comparable & Hashable & Codable>:
    Hashable, Codable, /*MutableWeightedEdge,*/ CustomStringConvertible {

    public var weight: W

    public init(weight: W) {
        self.weight = weight
    }

    public var description: String { "w=\(weight)" }
}

/// An edge property that combines a numeric weight with open-ended attributes.
public struct AnnotatedEdgeProperty<W: Numeric & Comparable & Hashable & Codable>:
    Hashable, Codable, /*MutableWeightedEdge, MutableAnnotatedEdge,*/ CustomStringConvertible {

    public var weight: W
    public var attributes: [String: String]

    public init(weight: W, attributes: [String: String] = [:]) {
        self.weight = weight
        self.attributes = attributes
    }

    public var description: String {
        guard !attributes.isEmpty else { return "w=\(weight)" }
        let attrs = attributes.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
        return "w=\(weight) [\(attrs)]"
    }
}

/// A full network-flow edge property.
/// Stores capacity, current flow, lower bound, and cost, together with
/// optional attributes for visualisation or external tooling.
public struct FlowEdgeProperty: Hashable, Codable, /*FlowEdge, MutableAnnotatedEdge,*/ CustomStringConvertible {

    public var capacity: Double
    public var flow: Double
    public var lowerBound: Double
    public var cost: Double
    public var attributes: [String: String]

    public init(
        capacity: Double,
        flow: Double = 0.0,
        lowerBound: Double = 0.0,
        cost: Double = 0.0,
        attributes: [String: String] = [:]
    ) {
        precondition(capacity >= 0, "capacity must be non-negative")
        precondition(lowerBound >= 0, "lowerBound must be non-negative")
        precondition(lowerBound <= capacity, "lowerBound must not exceed capacity")
        self.capacity = capacity
        self.flow = flow
        self.lowerBound = lowerBound
        self.cost = cost
        self.attributes = attributes
    }

    /// Remaining spare capacity on this edge.
    public var residualCapacity: Double { capacity - flow }

    /// True when no additional flow can be routed along this edge.
    public var isSaturated: Bool { flow >= capacity }

    public var description: String {
        "FlowEdge(flow: \(flow)/\(capacity), lb: \(lowerBound), cost: \(cost))"
    }
}
