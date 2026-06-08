//
//  EdgeAttributes.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Protocol

/// A protocol that any edge-property type must satisfy.
///
/// Conforming types are stored per-edge in `AdjacentGraph.edgeProperties`
/// (the existing `[Edge: W]` dictionary) and are now accessible through the
/// richer read/write API added to `AdjacentGraph`.
public protocol EdgeAttributesProtocol: Hashable & Codable {
    /// Human-readable label (may display cost, name, or relation).
    var label: String { get set }
}

// MARK: - Concrete types

/// A plain weighted edge carrying a single `Double` cost.
public struct WeightedEdge: EdgeAttributesProtocol {
    public var label: String
    public var weight: Double

    public init(weight: Double, label: String = "") {
        self.weight = weight
        self.label = label.isEmpty ? String(weight) : label
    }
}

/// An edge annotated with an arbitrary `userInfo` dictionary.
public struct AnnotatedEdge: EdgeAttributesProtocol {
    public var label: String
    public var userInfo: [String: String]

    public init(label: String, userInfo: [String: String] = [:]) {
        self.label = label
        self.userInfo = userInfo
    }
}

/// An edge that models a flow arc, carrying:
///   - `capacity`   – maximum allowable flow
///   - `flow`       – current flow (read/write)
///   - `cost`       – cost per unit of flow (for min-cost flow)
///   - `lowerBound` – minimum required flow
///
/// Residual capacity is derived as `capacity − flow`.
public struct FlowEdge: EdgeAttributesProtocol {

    public var label: String

    /// Maximum flow this arc can carry.
    public var capacity: Double

    /// Current flow along this arc (0 ≤ flow ≤ capacity).
    public var flow: Double {
        didSet { flow = min(max(flow, lowerBound), capacity) }
    }

    /// Cost per unit of flow (negative = profit).
    public var cost: Double

    /// Minimum flow that must pass along this arc.
    public var lowerBound: Double

    /// Remaining spare capacity (capacity − flow).
    public var residualCapacity: Double { capacity - flow }

    /// Returns true when the arc is saturated (flow == capacity).
    public var isSaturated: Bool { flow >= capacity }

    public init(capacity: Double, flow: Double = 0, cost: Double = 0, lowerBound: Double = 0, label: String = "") {
        self.capacity = capacity
        self.flow = flow
        self.cost = cost
        self.lowerBound = lowerBound
        self.label = label.isEmpty ? "cap:\(capacity)" : label
    }
}
