import Foundation
import SwiftLayout

// MARK: - Render model

public struct VisualPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public enum VisualPathSegment: Hashable, Sendable {
    case line(start: VisualPoint, end: VisualPoint)
    case cubicCurve(start: VisualPoint, control1: VisualPoint, control2: VisualPoint, end: VisualPoint)
}

public struct VisualArrowhead: Hashable, Sendable {
    public var tip: VisualPoint
    public var angle: Double
    public var left: VisualPoint
    public var right: VisualPoint

    public init(tip: VisualPoint, angle: Double, left: VisualPoint, right: VisualPoint) {
        self.tip = tip
        self.angle = angle
        self.left = left
        self.right = right
    }
}

public struct VisualPartition: Sendable {
    public var label: String
    public var members: [Int]
    public var color: String

    public init(label: String, members: [Int], color: String) {
        self.label = label
        self.members = members
        self.color = color
    }
}

public struct VisualHull: Sendable {
    public var members: [Int]
    public var fillColor: String
    public var strokeColor: String
    public var label: String?

    public init(members: [Int], fillColor: String, strokeColor: String, label: String? = nil) {
        self.members = members
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.label = label
    }
}

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

public struct VisualNode: Sendable {
    public let id: Int
    public var label: String
    public var x: Double
    public var y: Double
    public var color: String?
    public var isHighlighted: Bool
    public var isCutNode: Bool
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

public struct VisualEdge: Sendable {
    public let id: UInt64
    public let from: Int
    public let to: Int
    public var label: String?
    public var isHighlighted: Bool
    public var sequenceNumber: Int?
    public var waypoints: [VisualPoint]
    public var segments: [VisualPathSegment]
    public var labelPosition: VisualPoint?
    public var arrowhead: VisualArrowhead?
    public var isReversed: Bool
    public var isSelfLoop: Bool
    public var isMatched: Bool

    public init(id: UInt64 = 0, from: Int, to: Int, label: String? = nil,
                isHighlighted: Bool = false, sequenceNumber: Int? = nil,
                waypoints: [VisualPoint] = [], segments: [VisualPathSegment] = [],
                labelPosition: VisualPoint? = nil, arrowhead: VisualArrowhead? = nil,
                isReversed: Bool = false, isSelfLoop: Bool = false,
                isMatched: Bool = false) {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
        self.isHighlighted = isHighlighted
        self.sequenceNumber = sequenceNumber
        self.waypoints = waypoints
        self.segments = segments
        self.labelPosition = labelPosition
        self.arrowhead = arrowhead
        self.isReversed = isReversed
        self.isSelfLoop = isSelfLoop
        self.isMatched = isMatched
    }
}

public struct VisualGraph: Sendable {
    public var title: String
    public var nodes: [VisualNode]
    public var edges: [VisualEdge]
    public var width: Double
    public var height: Double
    public var hulls: [VisualHull]
    public var badges: [VisualBadge]
    public var partitions: [VisualPartition]
    public var isDirected: Bool

    public init(title: String = "Graph", nodes: [VisualNode] = [], edges: [VisualEdge] = [],
                width: Double = 800, height: Double = 600,
                hulls: [VisualHull] = [], badges: [VisualBadge] = [],
                partitions: [VisualPartition] = [], isDirected: Bool = true) {
        self.title = title
        self.nodes = nodes
        self.edges = edges
        self.width = width
        self.height = height
        self.hulls = hulls
        self.badges = badges
        self.partitions = partitions
        self.isDirected = isDirected
    }
}

// MARK: - Rust-backed layout

public enum GraphRankConstraint: Sendable {
    case preferred
    case pinned
}

public struct GraphRankHint: Sendable {
    public var rank: Int
    public var constraint: GraphRankConstraint

    public init(rank: Int, constraint: GraphRankConstraint = .preferred) {
        self.rank = rank
        self.constraint = constraint
    }
}

public enum GraphLayoutMode: Sendable {
    case hierarchical
    case bipartite(partitionU: [Int], partitionV: [Int], maxIterations: UInt32 = 8)
}

public enum GraphLayoutDirection: Sendable { case topToBottom, leftToRight }
public enum GraphLayoutRouting: Sendable { case straight, orthogonal, bezier }
public enum GraphLayoutAlgorithm: Sendable { case brandesKopf, medianRelax }

public struct GraphLayoutOptions: Sendable {
    public var title: String
    public var mode: GraphLayoutMode
    public var rankHints: [Int: GraphRankHint]
    public var highlightEdges: Set<Edge>
    public var highlightNodes: Set<Int>
    public var cutNodes: Set<Int>
    public var nodeColors: [Int: String]
    public var edgeLabels: [Edge: String]
    public var matchedEdges: Set<Edge>
    public var tourSequence: [Int]?
    public var componentGroups: [[Int]]?
    public var hullLabels: [String]?
    public var partitions: [VisualPartition]
    public var theme: GraphVisualTheme
    public var direction: GraphLayoutDirection
    public var routing: GraphLayoutRouting
    public var algorithm: GraphLayoutAlgorithm
    public var horizontalGap: Double
    public var verticalGap: Double
    public var relaxationPasses: UInt32
    public var crossingSweeps: UInt32
    public var canvasPadding: Double
    public var titleHeight: Double

    public init(title: String = "Graph Layout", mode: GraphLayoutMode = .hierarchical,
                rankHints: [Int: GraphRankHint] = [:], highlightEdges: Set<Edge> = [],
                highlightNodes: Set<Int> = [], cutNodes: Set<Int> = [],
                nodeColors: [Int: String] = [:], edgeLabels: [Edge: String] = [:],
                matchedEdges: Set<Edge> = [], tourSequence: [Int]? = nil,
                componentGroups: [[Int]]? = nil, hullLabels: [String]? = nil,
                partitions: [VisualPartition] = [], theme: GraphVisualTheme = .modernDark,
                direction: GraphLayoutDirection = .topToBottom,
                routing: GraphLayoutRouting = .bezier,
                algorithm: GraphLayoutAlgorithm = .brandesKopf,
                horizontalGap: Double = 80, verticalGap: Double = 80,
                relaxationPasses: UInt32 = 8, crossingSweeps: UInt32 = 4,
                canvasPadding: Double = 56, titleHeight: Double = 44) {
        self.title = title
        self.mode = mode
        self.rankHints = rankHints
        self.highlightEdges = highlightEdges
        self.highlightNodes = highlightNodes
        self.cutNodes = cutNodes
        self.nodeColors = nodeColors
        self.edgeLabels = edgeLabels
        self.matchedEdges = matchedEdges
        self.tourSequence = tourSequence
        self.componentGroups = componentGroups
        self.hullLabels = hullLabels
        self.partitions = partitions
        self.theme = theme
        self.direction = direction
        self.routing = routing
        self.algorithm = algorithm
        self.horizontalGap = horizontalGap
        self.verticalGap = verticalGap
        self.relaxationPasses = relaxationPasses
        self.crossingSweeps = crossingSweeps
        self.canvasPadding = canvasPadding
        self.titleHeight = titleHeight
    }
}

public enum GraphLayoutError: Error, Equatable, LocalizedError, Sendable {
    case invalidVertex(Int)
    case invalidRank(vertex: Int, rank: Int)
    case duplicatePartitionVertex(Int)
    case incompletePartitions(missing: [Int])
    case missingPosition(Int)
    case missingRoute(UInt64)
    case rust(String)

    public var errorDescription: String? {
        switch self {
        case .invalidVertex(let vertex): return "Vertex index \(vertex) is outside the graph."
        case .invalidRank(let vertex, let rank): return "Rank \(rank) for vertex \(vertex) is invalid."
        case .duplicatePartitionVertex(let vertex): return "Vertex \(vertex) occurs in both bipartite partitions."
        case .incompletePartitions(let missing): return "Bipartite partitions do not contain vertices: \(missing)."
        case .missingPosition(let vertex): return "The layout engine returned no position for vertex \(vertex)."
        case .missingRoute(let edgeID): return "The layout engine returned no route for edge \(edgeID)."
        case .rust(let message): return "Rust layout failed: \(message)"
        }
    }
}

/// Converts NetworkGraph data to the UniFFI contract and maps the complete Rust result
/// (ranks, routed segments, labels, arrowheads, and self-loops) into renderable geometry.
public struct GraphLayoutEngine: Sendable {
    public init() {}

    public func layout<V, W>(_ graph: AdjacentGraph<V, W>, options: GraphLayoutOptions = .init()) throws -> VisualGraph {
        let vertexCount = graph.vertexCount
        try validate(options: options, vertexCount: vertexCount)
        guard vertexCount > 0 else {
            return VisualGraph(title: options.title, isDirected: graph.kind == .directed)
        }

        let nodeDiameter = Float(options.theme.nodeRadius * 2)
        let nodes = try (0..<vertexCount).map { vertex -> FfiNode in
            let hint = options.rankHints[vertex]
            let rank = try hint.map { value -> UInt32 in
                guard value.rank >= 0, let converted = UInt32(exactly: value.rank) else {
                    throw GraphLayoutError.invalidRank(vertex: vertex, rank: value.rank)
                }
                return converted
            }
            return FfiNode(id: UInt64(vertex), width: nodeDiameter, height: nodeDiameter,
                           rankHint: rank, rankConstraint: hint?.constraint.ffi ?? .preferred)
        }

        let records = canonicalEdges(graph, options: options)
        let ffiEdges = records.map { record in
            let size = record.label.map { labelDimensions($0, theme: options.theme) }
            return FfiEdge(id: record.id, from: UInt64(record.edge.u), to: UInt64(record.edge.v),
                           labelWidth: size?.width, labelHeight: size?.height)
        }
        let config = FfiConfig(hGap: Float(options.horizontalGap), vGap: Float(options.verticalGap),
                               relaxPasses: options.relaxationPasses, sweeps: options.crossingSweeps,
                               algorithm: options.algorithm.ffi, routing: options.routing.ffi,
                               direction: options.direction.ffi)

        let result: FfiLayoutResult
        do {
            switch options.mode {
            case .hierarchical:
                result = try SwiftLayout.layout(nodes: nodes, edges: ffiEdges, config: config)
            case .bipartite(let partitionU, let partitionV, let maxIterations):
                result = try SwiftLayout.layoutBipartite(
                    nodes: nodes, edges: ffiEdges,
                    partitionU: partitionU.map(UInt64.init), partitionV: partitionV.map(UInt64.init),
                    directed: graph.kind == .directed, maxIterations: maxIterations, config: config
                )
            }
        } catch {
            throw GraphLayoutError.rust(String(describing: error))
        }

        let dx = options.canvasPadding - Double(result.bounds.minX)
        let dy = options.canvasPadding + options.titleHeight - Double(result.bounds.minY)
        let translate: (FfiPoint) -> VisualPoint = { point in
            VisualPoint(x: Double(point.x) + dx, y: Double(point.y) + dy)
        }
        let positions = Dictionary(uniqueKeysWithValues: result.positions.map { ($0.id, $0) })
        let routes = Dictionary(uniqueKeysWithValues: result.routes.map { ($0.id, $0) })

        let visualNodes = try (0..<vertexCount).map { vertex -> VisualNode in
            guard let position = positions[UInt64(vertex)] else { throw GraphLayoutError.missingPosition(vertex) }
            let point = translate(FfiPoint(x: position.x, y: position.y))
            return VisualNode(id: vertex, label: "\(vertex)", x: point.x, y: point.y,
                              color: options.nodeColors[vertex],
                              isHighlighted: options.highlightNodes.contains(vertex),
                              isCutNode: options.cutNodes.contains(vertex), rank: Int(position.rank))
        }

        let visualEdges = try records.map { record -> VisualEdge in
            guard let route = routes[record.id] else { throw GraphLayoutError.missingRoute(record.id) }
            return VisualEdge(
                id: record.id, from: record.edge.u, to: record.edge.v, label: record.label,
                isHighlighted: record.isHighlighted, sequenceNumber: record.sequenceNumber,
                waypoints: route.waypoints.map(translate),
                segments: route.segments.map { $0.visual(translate: translate) },
                labelPosition: route.labelPosition.map(translate),
                arrowhead: route.arrowhead.map { arrow in
                    VisualArrowhead(tip: translate(arrow.tip), angle: Double(arrow.angle),
                                    left: translate(arrow.left), right: translate(arrow.right))
                },
                isReversed: route.reversed, isSelfLoop: route.isSelfLoop,
                isMatched: record.isMatched
            )
        }

        let hulls = makeHulls(options: options)
        let badges = makeBadges(tour: options.tourSequence, edges: visualEdges, directed: graph.kind == .directed)
        return VisualGraph(
            title: options.title, nodes: visualNodes, edges: visualEdges,
            width: max(1, Double(result.bounds.width) + options.canvasPadding * 2),
            height: max(1, Double(result.bounds.height) + options.canvasPadding * 2 + options.titleHeight),
            hulls: hulls, badges: badges, partitions: options.partitions,
            isDirected: graph.kind == .directed
        )
    }

    private struct EdgeRecord {
        let id: UInt64
        let edge: Edge
        let label: String?
        let isHighlighted: Bool
        let isMatched: Bool
        let sequenceNumber: Int?
    }

    private func canonicalEdges<V, W>(_ graph: AdjacentGraph<V, W>, options: GraphLayoutOptions) -> [EdgeRecord] {
        var tourSteps: [Edge: Int] = [:]
        if let tour = options.tourSequence {
            for (step, pair) in zip(tour, tour.dropFirst()).enumerated() {
                tourSteps[Edge(u: pair.0, v: pair.1)] = step + 1
            }
        }
        var seen = Set<Edge>()
        var output: [EdgeRecord] = []
        for edge in graph.edges {
            let key: Edge
            if graph.kind == .undirected {
                key = edge.u <= edge.v ? edge : edge.reversed()
                guard seen.insert(key).inserted else { continue }
            } else {
                key = edge
            }
            let reverse = key.reversed()
            let highlighted = options.highlightEdges.contains(key) ||
                (graph.kind == .undirected && options.highlightEdges.contains(reverse)) ||
                tourSteps[key] != nil || (graph.kind == .undirected && tourSteps[reverse] != nil)
            let matched = options.matchedEdges.contains(key) ||
                (graph.kind == .undirected && options.matchedEdges.contains(reverse))
            output.append(EdgeRecord(
                id: UInt64(output.count), edge: key,
                label: options.edgeLabels[key] ?? (graph.kind == .undirected ? options.edgeLabels[reverse] : nil),
                isHighlighted: highlighted || matched, isMatched: matched,
                sequenceNumber: tourSteps[key] ?? (graph.kind == .undirected ? tourSteps[reverse] : nil)
            ))
        }
        return output
    }

    private func validate(options: GraphLayoutOptions, vertexCount: Int) throws {
        let referenced = Set(options.rankHints.keys)
            .union(options.highlightNodes).union(options.cutNodes)
            .union(options.componentGroups?.flatMap { $0 } ?? [])
            .union(options.tourSequence ?? [])
        if let invalid = referenced.first(where: { $0 < 0 || $0 >= vertexCount }) {
            throw GraphLayoutError.invalidVertex(invalid)
        }
        for (vertex, hint) in options.rankHints where hint.rank < 0 || UInt32(exactly: hint.rank) == nil {
            throw GraphLayoutError.invalidRank(vertex: vertex, rank: hint.rank)
        }
        if case .bipartite(let u, let v, _) = options.mode {
            if let invalid = (u + v).first(where: { $0 < 0 || $0 >= vertexCount }) {
                throw GraphLayoutError.invalidVertex(invalid)
            }
            let uSet = Set(u), vSet = Set(v)
            if let duplicate = uSet.intersection(vSet).first {
                throw GraphLayoutError.duplicatePartitionVertex(duplicate)
            }
            let missing = Set(0..<vertexCount).subtracting(uSet.union(vSet)).sorted()
            if !missing.isEmpty { throw GraphLayoutError.incompletePartitions(missing: missing) }
        }
    }

    private func labelDimensions(_ label: String, theme: GraphVisualTheme) -> (width: Float, height: Float) {
        (Float(max(16, Double(label.count) * theme.edgeFontSize * 0.62 + 10)),
         Float(theme.edgeFontSize + 8))
    }

    private func makeHulls(options: GraphLayoutOptions) -> [VisualHull] {
        guard let groups = options.componentGroups else { return [] }
        return groups.enumerated().map { index, members in
            let color = options.theme.palette[index % options.theme.palette.count]
            let label = options.hullLabels?[safe: index] ?? "C\(index + 1)"
            return VisualHull(members: members, fillColor: color, strokeColor: color, label: label)
        }
    }

    private func makeBadges(tour: [Int]?, edges: [VisualEdge], directed: Bool) -> [VisualBadge] {
        guard let tour else { return [] }
        return zip(tour, tour.dropFirst()).enumerated().compactMap { step, pair in
            guard let edge = edges.first(where: {
                ($0.from == pair.0 && $0.to == pair.1) || (!directed && $0.from == pair.1 && $0.to == pair.0)
            }), let position = edge.labelPosition ?? edge.pathMidpoint else { return nil }
            return VisualBadge(position: position, number: step + 1)
        }
    }
}

// MARK: - Compatibility entry points

public enum LayoutBridge {
    public static func layoutSugiyama<V, W>(
        graph: AdjacentGraph<V, W>, title: String = "Graph Layout",
        highlightEdges: Set<Edge> = [], highlightNodes: Set<Int> = [], cutNodes: Set<Int> = [],
        nodeColors: [Int: String] = [:], edgeLabels: [Edge: String] = [:],
        tourSequence: [Int]? = nil, componentGroups: [[Int]]? = nil,
        rankHints: [Int: Int] = [:], theme: GraphVisualTheme = .modernDark
    ) throws -> VisualGraph {
        let hints = rankHints.mapValues { GraphRankHint(rank: $0, constraint: .preferred) }
        return try GraphLayoutEngine().layout(graph, options: GraphLayoutOptions(
            title: title, rankHints: hints, highlightEdges: highlightEdges,
            highlightNodes: highlightNodes, cutNodes: cutNodes, nodeColors: nodeColors,
            edgeLabels: edgeLabels, tourSequence: tourSequence,
            componentGroups: componentGroups, theme: theme
        ))
    }

    public static func layoutBipartite<V, W>(
        graph: AdjacentGraph<V, W>, partitionU: [Int], partitionV: [Int],
        labelU: String = "U", labelV: String = "V", matchedEdges: Set<Edge> = [],
        edgeLabels: [Edge: String] = [:], nodeColors: [Int: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) throws -> VisualGraph {
        let partitions = [
            VisualPartition(label: labelU, members: partitionU, color: theme.palette[0]),
            VisualPartition(label: labelV, members: partitionV, color: theme.palette[3])
        ]
        return try GraphLayoutEngine().layout(graph, options: GraphLayoutOptions(
            title: "Bipartite Layout", mode: .bipartite(partitionU: partitionU, partitionV: partitionV),
            nodeColors: nodeColors, edgeLabels: edgeLabels, matchedEdges: matchedEdges,
            partitions: partitions, theme: theme, direction: .leftToRight
        ))
    }

    public static func layoutWithRankHints<V, W>(
        graph: AdjacentGraph<V, W>, rankHints: [Int: Int],
        title: String = "Rank-Constrained Layout", highlightEdges: Set<Edge> = [],
        nodeColors: [Int: String] = [:], edgeLabels: [Edge: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) throws -> VisualGraph {
        let pinned = rankHints.mapValues { GraphRankHint(rank: $0, constraint: .pinned) }
        return try GraphLayoutEngine().layout(graph, options: GraphLayoutOptions(
            title: title, rankHints: pinned, highlightEdges: highlightEdges,
            nodeColors: nodeColors, edgeLabels: edgeLabels, theme: theme
        ))
    }

    public static func layoutComponents<V, W>(
        graph: AdjacentGraph<V, W>, componentGroups: [[Int]], hullLabels: [String]? = nil,
        title: String = "Components", highlightEdges: Set<Edge> = [],
        nodeColors: [Int: String] = [:], edgeLabels: [Edge: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) throws -> VisualGraph {
        try GraphLayoutEngine().layout(graph, options: GraphLayoutOptions(
            title: title, highlightEdges: highlightEdges, nodeColors: nodeColors,
            edgeLabels: edgeLabels, componentGroups: componentGroups,
            hullLabels: hullLabels, theme: theme
        ))
    }

    @available(*, deprecated, renamed: "layoutComponents(graph:componentGroups:hullLabels:title:highlightEdges:nodeColors:edgeLabels:theme:)")
    public static func layoutWithComponentHulls<V, W>(
        graph: AdjacentGraph<V, W>, componentGroups: [[Int]], hullLabels: [String]? = nil,
        title: String = "Components", highlightEdges: Set<Edge> = [],
        nodeColors: [Int: String] = [:], edgeLabels: [Edge: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) throws -> VisualGraph {
        try layoutComponents(graph: graph, componentGroups: componentGroups, hullLabels: hullLabels,
                             title: title, highlightEdges: highlightEdges,
                             nodeColors: nodeColors, edgeLabels: edgeLabels, theme: theme)
    }

    /// Circular layout remains in Swift because it is intentionally independent of hierarchical routing.
    public static func layoutCircular<V, W>(
        graph: AdjacentGraph<V, W>, title: String = "Circular Layout", tour: [Int]? = nil,
        highlightEdges: Set<Edge> = [], nodeColors: [Int: String] = [:],
        theme: GraphVisualTheme = .modernDark
    ) -> VisualGraph {
        let n = graph.vertexCount
        guard n > 0 else { return VisualGraph(title: title, isDirected: graph.kind == .directed) }
        let width = 800.0, height = 800.0, radius = 280.0
        var positions: [Int: VisualPoint] = [:]
        let nodes = (0..<n).map { vertex -> VisualNode in
            let angle = Double(vertex) / Double(n) * 2 * Double.pi - Double.pi / 2
            let point = VisualPoint(x: width / 2 + radius * cos(angle), y: height / 2 + radius * sin(angle))
            positions[vertex] = point
            return VisualNode(id: vertex, label: "\(vertex)", x: point.x, y: point.y, color: nodeColors[vertex])
        }
        let pairs = tour.map { Array(zip($0, $0.dropFirst())) } ?? []
        var seen = Set<Edge>()
        var edges: [VisualEdge] = []
        for edge in graph.edges {
            let key = graph.kind == .undirected && edge.u > edge.v ? edge.reversed() : edge
            if graph.kind == .undirected && !seen.insert(key).inserted { continue }
            guard let start = positions[key.u], let end = positions[key.v] else { continue }
            let step = pairs.firstIndex { pair in
                (pair.0 == key.u && pair.1 == key.v) ||
                    (graph.kind == .undirected && pair.0 == key.v && pair.1 == key.u)
            }.map { $0 + 1 }
            let highlighted = highlightEdges.contains(key) ||
                (graph.kind == .undirected && highlightEdges.contains(key.reversed())) || step != nil
            edges.append(VisualEdge(id: UInt64(edges.count), from: key.u, to: key.v,
                                    isHighlighted: highlighted, sequenceNumber: step,
                                    waypoints: [start, end], segments: [.line(start: start, end: end)],
                                    isSelfLoop: key.u == key.v))
        }
        let badges = pairs.enumerated().compactMap { step, pair -> VisualBadge? in
            guard let start = positions[pair.0], let end = positions[pair.1] else { return nil }
            return VisualBadge(position: VisualPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2), number: step + 1)
        }
        return VisualGraph(title: title, nodes: nodes, edges: edges, width: width, height: height,
                           badges: badges, isDirected: graph.kind == .directed)
    }
}

private extension GraphRankConstraint {
    var ffi: FfiRankConstraint { self == .pinned ? .pinned : .preferred }
}

private extension GraphLayoutDirection {
    var ffi: FfiDirection { self == .leftToRight ? .leftToRight : .topToBottom }
}

private extension GraphLayoutRouting {
    var ffi: FfiRoutingStyle {
        switch self { case .straight: return .straight; case .orthogonal: return .orthogonal; case .bezier: return .bezier }
    }
}

private extension GraphLayoutAlgorithm {
    var ffi: FfiAlgorithm { self == .medianRelax ? .medianRelax : .brandesKopf }
}

private extension FfiPathSegment {
    func visual(translate: (FfiPoint) -> VisualPoint) -> VisualPathSegment {
        switch self {
        case .line(let start, let end): return .line(start: translate(start), end: translate(end))
        case .cubicCurve(let start, let control1, let control2, let end):
            return .cubicCurve(start: translate(start), control1: translate(control1),
                               control2: translate(control2), end: translate(end))
        }
    }
}

private extension VisualEdge {
    var pathMidpoint: VisualPoint? {
        guard let first = waypoints.first, let last = waypoints.last else { return nil }
        return VisualPoint(x: (first.x + last.x) / 2, y: (first.y + last.y) / 2)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
