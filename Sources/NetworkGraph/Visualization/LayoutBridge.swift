//
//  LayoutBridge.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// A 2D point for graph rendering.
public struct VisualPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// Visual representation of a vertex.
public struct VisualNode: Sendable {
    public let id: Int
    public var label: String
    public var x: Double
    public var y: Double
    public var color: String?
    public var isHighlighted: Bool

    public init(id: Int, label: String, x: Double = 0, y: Double = 0, color: String? = nil, isHighlighted: Bool = false) {
        self.id = id
        self.label = label
        self.x = x
        self.y = y
        self.color = color
        self.isHighlighted = isHighlighted
    }
}

/// Visual representation of an edge with routing waypoints and annotations.
public struct VisualEdge: Sendable {
    public let from: Int
    public let to: Int
    public var label: String?
    public var isHighlighted: Bool
    public var sequenceNumber: Int?
    public var waypoints: [VisualPoint]

    public init(from: Int, to: Int, label: String? = nil, isHighlighted: Bool = false, sequenceNumber: Int? = nil, waypoints: [VisualPoint] = []) {
        self.from = from
        self.to = to
        self.label = label
        self.isHighlighted = isHighlighted
        self.sequenceNumber = sequenceNumber
        self.waypoints = waypoints
    }
}

/// A fully positioned and styled graph ready for SVG / visual export.
public struct VisualGraph: Sendable {
    public var title: String
    public var nodes: [VisualNode]
    public var edges: [VisualEdge]
    public var width: Double
    public var height: Double

    public init(title: String = "Graph", nodes: [VisualNode] = [], edges: [VisualEdge] = [], width: Double = 800, height: Double = 600) {
        self.title = title
        self.nodes = nodes
        self.edges = edges
        self.width = width
        self.height = height
    }
}

/// Bridge between NetworkGraph and layout engines (Sugiyama, Layered, Circular).
public enum LayoutBridge {

    /// Generates a layered Sugiyama layout for an `AdjacentGraph`.
    public static func layoutSugiyama<V, W>(
        graph: AdjacentGraph<V, W>,
        title: String = "Graph Layout",
        highlightEdges: Set<Edge> = [],
        highlightNodes: Set<Int> = [],
        nodeColors: [Int: String] = [:],
        edgeLabels: [Edge: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        let n = graph.vertexCount
        guard n > 0 else { return VisualGraph(title: title) }

        // 1. Assign ranks / layers using BFS / longest-path
        let inDegrees = (0..<n).map { graph.indegree(vertex: $0) }
        var layerMap = Array(repeating: 0, count: n)

        var roots = (0..<n).filter { inDegrees[$0] == 0 }
        if roots.isEmpty { roots = [0] }

        var queue = roots
        var visited = Set(roots)

        while !queue.isEmpty {
            let u = queue.removeFirst()
            for v in graph.adjacent(of: u) {
                layerMap[v] = Swift.max(layerMap[v], layerMap[u] + 1)
                if !visited.contains(v) {
                    visited.insert(v)
                    queue.append(v)
                }
            }
        }

        // For unvisited components in cyclic / undirected graphs
        for u in 0..<n where !visited.contains(u) {
            layerMap[u] = 0
        }

        var layers: [[Int]] = []
        let maxLayer = layerMap.max() ?? 0
        for l in 0...maxLayer {
            let inLayer = (0..<n).filter { layerMap[$0] == l }
            if !inLayer.isEmpty {
                layers.append(inLayer)
            }
        }

        let hGap = 120.0
        let vGap = 100.0
        let padding = 80.0

        var maxNodesInLayer = 1
        for l in layers { maxNodesInLayer = Swift.max(maxNodesInLayer, l.count) }

        let width = Swift.max(800.0, Double(maxNodesInLayer) * hGap + 2 * padding)
        let height = Swift.max(600.0, Double(layers.count) * vGap + 2 * padding)

        var visualNodes: [VisualNode] = []
        var nodePositions = [Int: VisualPoint]()

        for (layerIdx, layer) in layers.enumerated() {
            let y = padding + Double(layerIdx) * vGap
            let layerWidth = Double(layer.count - 1) * hGap
            let startX = (width - layerWidth) / 2.0

            for (nodeIdx, u) in layer.enumerated() {
                let x = startX + Double(nodeIdx) * hGap
                let point = VisualPoint(x: x, y: y)
                nodePositions[u] = point

                let color = nodeColors[u]
                let isHl = highlightNodes.contains(u)
                visualNodes.append(VisualNode(id: u, label: "\(u)", x: x, y: y, color: color, isHighlighted: isHl))
            }
        }

        var visualEdges: [VisualEdge] = []
        var seenEdges = Set<Edge>()

        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let norm = Edge(u: edge.u, v: edge.v)
            if seenEdges.contains(norm) { continue }
            seenEdges.insert(norm)

            let isHl = highlightEdges.contains(norm) || highlightEdges.contains(norm.reversed())
            let label = edgeLabels[norm] ?? edgeLabels[norm.reversed()]

            let p1 = nodePositions[edge.u] ?? VisualPoint(x: 0, y: 0)
            let p2 = nodePositions[edge.v] ?? VisualPoint(x: 0, y: 0)

            visualEdges.append(VisualEdge(
                from: edge.u,
                to: edge.v,
                label: label,
                isHighlighted: isHl,
                waypoints: [p1, p2]
            ))
        }

        return VisualGraph(title: title, nodes: visualNodes, edges: visualEdges, width: width, height: height)
    }

    /// Generates a circular layout ideal for Hamilton cycles and TSP tours.
    public static func layoutCircular<V, W>(
        graph: AdjacentGraph<V, W>,
        title: String = "Circular Layout",
        tour: [Int]? = nil,
        highlightEdges: Set<Edge> = [],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        let n = graph.vertexCount
        let width = 800.0
        let height = 800.0
        let centerX = width / 2.0
        let centerY = height / 2.0
        let radius = 280.0

        var visualNodes: [VisualNode] = []
        var nodePositions = [Int: VisualPoint]()

        for i in 0..<n {
            let angle = (Double(i) / Double(n)) * 2.0 * .pi - .pi / 2.0
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            nodePositions[i] = VisualPoint(x: x, y: y)
            visualNodes.append(VisualNode(id: i, label: "\(i)", x: x, y: y))
        }

        var visualEdges: [VisualEdge] = []
        var tourEdges = Set<Edge>()

        if let t = tour {
            for i in 0..<(t.count - 1) {
                let e = Edge(u: t[i], v: t[i + 1])
                tourEdges.insert(e)
                tourEdges.insert(e.reversed())
            }
        }

        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let isHl = highlightEdges.contains(edge) || tourEdges.contains(edge)
            let p1 = nodePositions[edge.u]!
            let p2 = nodePositions[edge.v]!
            visualEdges.append(VisualEdge(from: edge.u, to: edge.v, isHighlighted: isHl, waypoints: [p1, p2]))
        }

        return VisualGraph(title: title, nodes: visualNodes, edges: visualEdges, width: width, height: height)
    }
}
