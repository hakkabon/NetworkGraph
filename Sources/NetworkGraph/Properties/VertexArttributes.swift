//
//  VertexAttributes.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Protocol

/// A protocol that any vertex-property type must satisfy.
///
/// Conforming types are stored per-vertex in `AdjacentGraph.vertexAttributes`
/// and accessed through the graph's `vertex(at:)` / `setVertex(_:at:)` API.
/// Custom vertex payloads (e.g. city names, node colours, ML features) should
/// conform to this protocol.
public protocol VertexAttributesProtocol: Hashable & Codable {
    /// Human-readable label shown in debug output and Graphviz exports.
    var label: String { get set }
}

// MARK: - Concrete types

/// A vertex that carries only a label — useful for symbol graphs and simple
/// named-node networks.
public struct LabeledVertex: VertexAttributesProtocol {
    public var label: String

    public init(label: String) {
        self.label = label
    }
}

/// A vertex extended with an arbitrary `userInfo` dictionary.
/// Handy for prototyping when you haven't yet modelled your domain type.
public struct AnnotatedVertex: VertexAttributesProtocol {
    public var label: String
    /// Arbitrary key-value annotations (serialisable as strings for `Codable`).
    public var userInfo: [String: String]

    public init(label: String, userInfo: [String: String] = [:]) {
        self.label = label
        self.userInfo = userInfo
    }
}

/// A vertex suitable for network-flow modelling: records excess flow,
/// a height label (for push-relabel), and a demand (for supply/demand problems).
public struct FlowVertex: VertexAttributesProtocol {
    public var label: String

    /// Net excess flow at this node (positive = surplus, negative = deficit).
    public var excess: Double

    /// Height label used by push-relabel algorithms.
    public var height: Int

    /// Fixed supply (positive) or demand (negative) for min-cost flow.
    public var supply: Double

    public init(label: String, excess: Double = 0, height: Int = 0, supply: Double = 0) {
        self.label = label
        self.excess = excess
        self.height = height
        self.supply = supply
    }
}
