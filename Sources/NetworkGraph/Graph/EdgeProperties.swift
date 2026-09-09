// EdgeProperties.swift
// NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Concrete Edge Property Types

/// A plain numeric weight on an edge.
public struct WeightedEdgeProperty<W: Numeric & Comparable & Hashable & Codable>:
    Hashable, Codable, CustomStringConvertible {

    public var weight: W

    public init(weight: W) {
        self.weight = weight
    }

    public var description: String { "w=\(weight)" }
}

/// An edge property that combines a numeric weight with open-ended attributes.
public struct AnnotatedEdgeProperty<W: Numeric & Comparable & Hashable & Codable>:
    Hashable, Codable, CustomStringConvertible {

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
public struct FlowEdgeProperty: Hashable, Codable, CustomStringConvertible {

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
