// VertexProperties.swift
// NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Concrete Vertex Property Types

/// A plain vertex with no additional properties.
/// Useful as a zero-cost stand-in when vertex metadata is not needed.
public struct SimpleVertexProperty: Hashable, Codable {
    public init() {}
}

/// A vertex property that holds a human-readable label.
public struct LabeledVertexProperty: Hashable, Codable, CustomStringConvertible {
    public var label: String

    public init(label: String = "") {
        self.label = label
    }

    public var description: String { label }
}

/// A vertex property that bundles a label with an open-ended attribute dictionary,
/// suitable for rich node metadata (e.g. colour, shape, tooltip in a visualisation).
public struct AnnotatedVertexProperty: Hashable, Codable, CustomStringConvertible {
    public var label: String
    public var attributes: [String: String]

    public init(label: String = "", attributes: [String: String] = [:]) {
        self.label = label
        self.attributes = attributes
    }

    public var description: String {
        guard !attributes.isEmpty else { return label }
        let attrs = attributes.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
        return "\(label) [\(attrs)]"
    }
}

/// A vertex property for network-flow models.
/// Each vertex may have a supply (positive) or demand (negative) value
/// and optional metadata carried in an attribute dictionary.
public struct FlowVertexProperty: Hashable, Codable, CustomStringConvertible {
    public var label: String
    public var supply: Double
    public var attributes: [String: String]

    public init(label: String = "", supply: Double = 0.0, attributes: [String: String] = [:]) {
        self.label = label
        self.supply = supply
        self.attributes = attributes
    }

    public var description: String {
        "FlowVertex(label: \(label), supply: \(supply))"
    }
}
