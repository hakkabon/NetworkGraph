//
//  LayoutBridge.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Core Visual Primitives

/// A 2D point for graph rendering.
public struct VisualPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// A named partition lane shown as a labelled column or row divider.
public struct VisualPartition: Sendable {
    /// Human-readable label (e.g. "U", "V", "Workers", "Jobs").
    public var label: String
    /// Vertex indices belonging to this partition.
    public var members: [Int]
    /// Accent color for the partition lane background (CSS hex, 10% opacity applied automatically).
    public var color: String

    public init(label: String, members: [Int], color: String) {
        self.label = label
        self.members = members
        self.color = color
    }
}

/// A bounding hull (rounded rectangle) drawn behind a group of vertices —
/// used to delineate connected components, SCCs, cliques, or matching sides.
public struct VisualHull: Sendable {
    /// Vertex indices enclosed by the hull.
    public var members: [Int]
    /// CSS hex fill color (applied at reduced opacity).
    public var fillColor: String
    /// CSS hex stroke color.
    public var strokeColor: String
    /// Optional text label shown at the top-left of the hull.
    public var label: String?

    public init(members: [Int], fillColor: String, strokeColor: String, label: String? = nil) {
        self.members = members
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.label = label
    }
}

/// A small numbered badge (circle) placed on an edge midpoint or vertex to indicate
/// step sequence in a tour (TSP, Euler, Chinese Postman, k-shortest path).
public struct VisualBadge: Sendable {
    public var position: VisualPoint
    public var number: Int
    public var fillColor: String
    public var textColor: String

    public init(position: VisualPoint, number: Int, fillColor: String = "#f43f5e", textColor: String = "#ffffff") {
        self.position = position
        self.number = number
        self.fillColor = fillColor
        self.textColor = textColor
    }
}

/// Visual representation of a vertex.
public struct VisualNode: Sendable {
    public let id: Int
    public var label: String
    public var x: Double
    public var y: Double
    /// CSS hex fill override; nil = use theme default.
    public var color: String?
    public var isHighlighted: Bool
    /// Render a diamond/star shape to indicate a cut node (articulation point).
    public var isCutNode: Bool
    /// Rank / layer index for documentation and rank-constraint debugging.
    public var rank: Int

    public init(id: Int, label: String, x: Double = 0, y: Double = 0,
                color: String? = nil, isHighlighted: Bool = false,
                isCutNode: Bool = false, rank: Int = 0) {
        self.id = id
        self.label = label
        self.x = x
        self.y = y
        self.color = color
        self.isHighlighted = isHighlighted
        self.isCutNode = isCutNode
        self.rank = rank
    }
}

/// Visual representation of an edge with routing waypoints and annotations.
public struct VisualEdge: Sendable {
    public let from: Int
    public let to: Int
    public var label: String?
    public var isHighlighted: Bool
    /// Step number in a tour / path sequence (used to render numbered badges).
    public var sequenceNumber: Int?
    /// Control points: [start, ...intermediates..., end] for straight or curved rendering.
    public var waypoints: [VisualPoint]
    /// When true the edge is a matching pair — rendered with a distinct paired style.
    public var isMatched: Bool

    public init(from: Int, to: Int, label: String? = nil, isHighlighted: Bool = false,
                sequenceNumber: Int? = nil, waypoints: [VisualPoint] = [], isMatched: Bool = false) {
        self.from = from
        self.to = to
        self.label = label
        self.isHighlighted = isHighlighted
        self.sequenceNumber = sequenceNumber
        self.waypoints = waypoints
        self.isMatched = isMatched
    }
}

/// A fully positioned and styled graph ready for SVG / visual export.
public struct VisualGraph: Sendable {
    public var title: String
    public var nodes: [VisualNode]
    public var edges: [VisualEdge]
    public var width: Double
    public var height: Double

    /// Bounding hulls for groups (components, SCCs, cliques).
    public var hulls: [VisualHull]
    /// Sequence badges for tour steps.
    public var badges: [VisualBadge]
    /// Named partition lanes (bipartite U/V, assignment workers/jobs).
    public var partitions: [VisualPartition]

    public init(title: String = "Graph", nodes: [VisualNode] = [], edges: [VisualEdge] = [],
                width: Double = 800, height: Double = 600,
                hulls: [VisualHull] = [], badges: [VisualBadge] = [],
                partitions: [VisualPartition] = []) {
        self.title = title
        self.nodes = nodes
        self.edges = edges
        self.width = width
        self.height = height
        self.hulls = hulls
        self.badges = badges
        self.partitions = partitions
    }
}

// MARK: - LayoutBridge

/// Bridge between NetworkGraph and layout engines (Sugiyama, Layered, Bipartite, Circular).
public enum LayoutBridge {

    // MARK: - 1. Sugiyama Hierarchical Layout

    /// Generates a layered Sugiyama layout for an `AdjacentGraph`.
    ///
    /// - Parameters:
    ///   - graph: The graph to lay out.
    ///   - title: Title displayed in the SVG header.
    ///   - highlightEdges: Edges to draw with the accent glow stroke.
    ///   - highlightNodes: Vertex indices to draw with the accent ring.
    ///   - cutNodes: Vertex indices to mark with the cut-node diamond indicator.
    ///   - nodeColors: Per-vertex CSS hex fill overrides.
    ///   - edgeLabels: Per-edge annotation text (e.g. "4/10" for flow/capacity).
    ///   - tourSequence: Ordered vertex sequence forming a highlighted tour; edges between
    ///                   consecutive vertices receive a step badge.
    ///   - componentGroups: Groups of vertex indices to enclose in colored bounding hulls.
    ///   - rankHints: Optional forced rank (layer) for specific vertices. Vertices with a hint
    ///                are placed on that layer regardless of the computed longest-path rank.
    ///   - theme: Visual theme (colors, sizes).
    public static func layoutSugiyama<V, W>(
        graph: AdjacentGraph<V, W>,
        title: String = "Graph Layout",
        highlightEdges: Set<Edge> = [],
        highlightNodes: Set<Int> = [],
        cutNodes: Set<Int> = [],
        nodeColors: [Int: String] = [:],
        edgeLabels: [Edge: String] = [:],
        tourSequence: [Int]? = nil,
        componentGroups: [[Int]]? = nil,
        rankHints: [Int: Int] = [:],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        let n = graph.vertexCount
        guard n > 0 else { return VisualGraph(title: title) }

        // ── Rank Assignment (Longest-Path BFS + optional forced hints) ──────────
        let inDegrees = (0..<n).map { graph.indegree(vertex: $0) }
        var layerMap = Array(repeating: 0, count: n)

        // Apply forced rank hints first
        for (v, r) in rankHints { if v < n { layerMap[v] = r } }

        var roots = (0..<n).filter { inDegrees[$0] == 0 && rankHints[$0] == nil }
        if roots.isEmpty { roots = (0..<n).filter { rankHints[$0] == nil && inDegrees[$0] == 0 } }
        if roots.isEmpty { roots = [0] }

        var queue = roots
        var visited: Set<Int> = Set(roots)
        // Seed hinted vertices as visited so BFS respects their forced rank
        for (v, _) in rankHints { visited.insert(v) }

        while !queue.isEmpty {
            let u = queue.removeFirst()
            for v in graph.adjacent(of: u) {
                if rankHints[v] == nil {
                    layerMap[v] = Swift.max(layerMap[v], layerMap[u] + 1)
                }
                if !visited.contains(v) {
                    visited.insert(v)
                    queue.append(v)
                }
            }
        }
        for u in 0..<n where !visited.contains(u) { layerMap[u] = 0 }

        // ── Layer → Pixel coordinates ─────────────────────────────────────────
        var layerBuckets: [[Int]] = []
        let maxLayer = layerMap.max() ?? 0
        for l in 0...maxLayer {
            let inLayer = (0..<n).filter { layerMap[$0] == l }
            if !inLayer.isEmpty { layerBuckets.append(inLayer) }
        }

        let hGap = 130.0
        let vGap = 110.0
        let padding = 90.0

        let maxNodesInLayer = layerBuckets.map { $0.count }.max() ?? 1
        let width  = Swift.max(800.0, Double(maxNodesInLayer) * hGap + 2 * padding)
        let height = Swift.max(600.0, Double(layerBuckets.count) * vGap + 2 * padding)

        var visualNodes: [VisualNode] = []
        var nodePositions = [Int: VisualPoint]()

        for (layerIdx, layer) in layerBuckets.enumerated() {
            let y = padding + Double(layerIdx) * vGap
            let layerWidth = Double(layer.count - 1) * hGap
            let startX = (width - layerWidth) / 2.0

            for (nodeIdx, u) in layer.enumerated() {
                let x = startX + Double(nodeIdx) * hGap
                nodePositions[u] = VisualPoint(x: x, y: y)
                visualNodes.append(VisualNode(
                    id: u, label: "\(u)", x: x, y: y,
                    color: nodeColors[u],
                    isHighlighted: highlightNodes.contains(u),
                    isCutNode: cutNodes.contains(u),
                    rank: layerIdx
                ))
            }
        }

        // ── Edges ─────────────────────────────────────────────────────────────
        var visualEdges: [VisualEdge] = []
        var seenEdges = Set<Edge>()

        // Build tour-edge lookup for sequence badges
        var tourEdgeSet = Set<Edge>()
        var tourStepMap = [Edge: Int]()
        if let tour = tourSequence {
            for i in 0..<(tour.count - 1) {
                let e = Edge(u: tour[i], v: tour[i + 1])
                tourEdgeSet.insert(e); tourEdgeSet.insert(e.reversed())
                tourStepMap[e] = i + 1
            }
        }

        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let norm = Edge(u: edge.u, v: edge.v)
            if seenEdges.contains(norm) { continue }
            seenEdges.insert(norm)

            let isHl = highlightEdges.contains(norm) || highlightEdges.contains(norm.reversed())
                    || tourEdgeSet.contains(norm)
            let label = edgeLabels[norm] ?? edgeLabels[norm.reversed()]
            let step = tourStepMap[norm] ?? tourStepMap[norm.reversed()]

            let p1 = nodePositions[edge.u] ?? VisualPoint(x: 0, y: 0)
            let p2 = nodePositions[edge.v] ?? VisualPoint(x: 0, y: 0)

            visualEdges.append(VisualEdge(
                from: edge.u, to: edge.v,
                label: label, isHighlighted: isHl,
                sequenceNumber: step,
                waypoints: [p1, p2]
            ))
        }

        // ── Tour Badges ───────────────────────────────────────────────────────
        var badges: [VisualBadge] = []
        for ve in visualEdges {
            guard let step = ve.sequenceNumber, ve.waypoints.count >= 2 else { continue }
            let p1 = ve.waypoints[0]
            let p2 = ve.waypoints[ve.waypoints.count - 1]
            let mid = VisualPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
            badges.append(VisualBadge(position: mid, number: step))
        }

        // ── Component Hulls ───────────────────────────────────────────────────
        var hulls: [VisualHull] = []
        if let groups = componentGroups {
            let hullColors = theme.palette
            for (i, group) in groups.enumerated() {
                let color = hullColors[i % hullColors.count]
                hulls.append(VisualHull(
                    members: group,
                    fillColor: color,
                    strokeColor: color,
                    label: "C\(i + 1)"
                ))
            }
        }

        return VisualGraph(title: title, nodes: visualNodes, edges: visualEdges,
                           width: width, height: height,
                           hulls: hulls, badges: badges)
    }

    // MARK: - 2. Bipartite Layout with Rank Constraints

    /// Generates a two-column bipartite layout with explicit rank-pinning.
    ///
    /// Left column = `partitionU` (rank 0), right column = `partitionV` (rank 1).
    /// Matched edges are drawn with `isMatched = true` for a distinct visual style.
    ///
    /// - Parameters:
    ///   - graph: The bipartite graph.
    ///   - partitionU: Vertex indices in the left partition (U side).
    ///   - partitionV: Vertex indices in the right partition (V side).
    ///   - labelU: Human-readable name for the U partition (default "U").
    ///   - labelV: Human-readable name for the V partition (default "V").
    ///   - matchedEdges: Edges in the current matching — highlighted distinctively.
    ///   - edgeLabels: Optional per-edge annotation text.
    ///   - nodeColors: Per-vertex fill overrides.
    ///   - theme: Visual theme.
    public static func layoutBipartite<V, W>(
        graph: AdjacentGraph<V, W>,
        partitionU: [Int],
        partitionV: [Int],
        labelU: String = "U",
        labelV: String = "V",
        matchedEdges: Set<Edge> = [],
        edgeLabels: [Edge: String] = [:],
        nodeColors: [Int: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        let sideGap = 260.0
        let vGap    = 80.0
        let padding = 80.0

        let rowCountU = partitionU.count
        let rowCountV = partitionV.count
        let maxRows = Swift.max(rowCountU, rowCountV)

        let width  = Swift.max(700.0, sideGap + 2 * padding)
        let height = Swift.max(500.0, Double(maxRows) * vGap + 2 * padding)

        let xU = padding + 60
        let xV = width - padding - 60

        var nodePositions = [Int: VisualPoint]()
        var visualNodes:   [VisualNode] = []

        // ── Left (U) column ───────────────────────────────────────────────────
        for (i, u) in partitionU.enumerated() {
            let totalH = Double(rowCountU - 1) * vGap
            let startY = (height - totalH) / 2.0
            let y = startY + Double(i) * vGap
            nodePositions[u] = VisualPoint(x: xU, y: y)
            visualNodes.append(VisualNode(
                id: u, label: "\(u)", x: xU, y: y,
                color: nodeColors[u] ?? theme.palette[0],
                rank: 0
            ))
        }

        // ── Right (V) column ──────────────────────────────────────────────────
        for (i, v) in partitionV.enumerated() {
            let totalH = Double(rowCountV - 1) * vGap
            let startY = (height - totalH) / 2.0
            let y = startY + Double(i) * vGap
            nodePositions[v] = VisualPoint(x: xV, y: y)
            visualNodes.append(VisualNode(
                id: v, label: "\(v)", x: xV, y: y,
                color: nodeColors[v] ?? theme.palette[3],
                rank: 1
            ))
        }

        // ── Edges ─────────────────────────────────────────────────────────────
        var visualEdges: [VisualEdge] = []
        var seenEdges = Set<Edge>()

        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let norm = Edge(u: edge.u, v: edge.v)
            if seenEdges.contains(norm) { continue }
            seenEdges.insert(norm)

            let isMatch = matchedEdges.contains(norm) || matchedEdges.contains(norm.reversed())
            let label = edgeLabels[norm] ?? edgeLabels[norm.reversed()]
            let p1 = nodePositions[edge.u] ?? VisualPoint(x: xU, y: 0)
            let p2 = nodePositions[edge.v] ?? VisualPoint(x: xV, y: 0)

            visualEdges.append(VisualEdge(
                from: edge.u, to: edge.v,
                label: label, isHighlighted: isMatch,
                waypoints: [p1, p2],
                isMatched: isMatch
            ))
        }

        // ── Partition metadata for the renderer ───────────────────────────────
        let partitions = [
            VisualPartition(label: labelU, members: partitionU, color: theme.palette[0]),
            VisualPartition(label: labelV, members: partitionV, color: theme.palette[3])
        ]

        return VisualGraph(
            title: "Bipartite Layout", nodes: visualNodes, edges: visualEdges,
            width: width, height: height,
            partitions: partitions
        )
    }

    // MARK: - 3. Layout with Explicit Rank Hints

    /// Sugiyama layout where specific vertices are pinned to an explicit layer.
    ///
    /// Use this for visualizing **assignment problems** (workers on layer 0, jobs on layer 1),
    /// **min-cost flow** (source on layer 0, sink on last layer), or any scenario where
    /// the algorithm output constrains vertex placement.
    ///
    /// - Parameter rankHints: `[vertexIndex: layerIndex]` — zero-based layer index.
    public static func layoutWithRankHints<V, W>(
        graph: AdjacentGraph<V, W>,
        rankHints: [Int: Int],
        title: String = "Rank-Constrained Layout",
        highlightEdges: Set<Edge> = [],
        nodeColors: [Int: String] = [:],
        edgeLabels: [Edge: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        layoutSugiyama(
            graph: graph,
            title: title,
            highlightEdges: highlightEdges,
            nodeColors: nodeColors,
            edgeLabels: edgeLabels,
            rankHints: rankHints,
            theme: theme
        )
    }

    // MARK: - 4. Component-Grouped Layout

    /// Sugiyama layout where each connected component is enclosed in a colored hull.
    ///
    /// Ideal for: Connected Components (2.5), SCCs (2.7), Cliques (2.11),
    /// Chromatic Color Classes (6.1), Matching Pairs (7.1).
    ///
    /// - Parameter componentGroups: Array of vertex-index groups; each becomes one hull.
    /// - Parameter hullLabels: Optional labels for each group.
    public static func layoutWithComponentHulls<V, W>(
        graph: AdjacentGraph<V, W>,
        componentGroups: [[Int]],
        hullLabels: [String]? = nil,
        title: String = "Components",
        highlightEdges: Set<Edge> = [],
        nodeColors: [Int: String] = [:],
        edgeLabels: [Edge: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        var vGraph = layoutSugiyama(
            graph: graph,
            title: title,
            highlightEdges: highlightEdges,
            nodeColors: nodeColors,
            edgeLabels: edgeLabels,
            componentGroups: componentGroups,
            theme: theme
        )

        // Override hull labels if provided
        if let labels = hullLabels {
            for i in 0..<Swift.min(labels.count, vGraph.hulls.count) {
                vGraph.hulls[i].label = labels[i]
            }
        }
        return vGraph
    }

    // MARK: - 5. Circular Layout

    /// Generates a circular layout ideal for Hamilton cycles and TSP tours.
    ///
    /// - Parameters:
    ///   - tour: Ordered vertex sequence; edges between consecutive vertices are highlighted
    ///           and receive sequence badges showing step numbers.
    ///   - nodeColors: Per-vertex fill overrides.
    public static func layoutCircular<V, W>(
        graph: AdjacentGraph<V, W>,
        title: String = "Circular Layout",
        tour: [Int]? = nil,
        highlightEdges: Set<Edge> = [],
        nodeColors: [Int: String] = [:],
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
            visualNodes.append(VisualNode(
                id: i, label: "\(i)", x: x, y: y,
                color: nodeColors[i]
            ))
        }

        var visualEdges: [VisualEdge] = []
        var tourEdgeSet = Set<Edge>()
        var tourStepMap = [Edge: Int]()

        if let t = tour {
            for i in 0..<(t.count - 1) {
                let e = Edge(u: t[i], v: t[i + 1])
                tourEdgeSet.insert(e); tourEdgeSet.insert(e.reversed())
                tourStepMap[e] = i + 1
            }
        }

        for edge in graph.edges {
            if graph.kind == .undirected && edge.u > edge.v { continue }
            let norm = Edge(u: edge.u, v: edge.v)
            let isHl = highlightEdges.contains(norm) || tourEdgeSet.contains(norm)
            let step = tourStepMap[norm] ?? tourStepMap[norm.reversed()]
            let p1 = nodePositions[edge.u]!
            let p2 = nodePositions[edge.v]!
            visualEdges.append(VisualEdge(
                from: edge.u, to: edge.v,
                isHighlighted: isHl,
                sequenceNumber: step,
                waypoints: [p1, p2]
            ))
        }

        // Tour sequence badges at edge midpoints
        var badges: [VisualBadge] = []
        for ve in visualEdges {
            guard let step = ve.sequenceNumber, ve.waypoints.count >= 2 else { continue }
            let p1 = ve.waypoints[0]; let p2 = ve.waypoints[1]
            badges.append(VisualBadge(
                position: VisualPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2),
                number: step
            ))
        }

        return VisualGraph(
            title: title, nodes: visualNodes, edges: visualEdges,
            width: width, height: height, badges: badges
        )
    }
}
