//
//  SVGGraphRenderer.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Renders a `VisualGraph` into standalone vector SVG markup with full support for
/// curved routes, edge costs/labels, tour sequence badges, component hulls, and cut-node indicators.
public enum SVGGraphRenderer {

    /// Generates standalone, responsive SVG markup for the given `VisualGraph`.
    public static func renderToSVG(_ vGraph: VisualGraph, theme: GraphVisualTheme = .modernDark) -> String {
        let width = Int(vGraph.width)
        let height = Int(vGraph.height)

        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)" width="100%" height="100%">
            <defs>
                <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stop-color="#0f172a" />
                    <stop offset="100%" stop-color="#020617" />
                </linearGradient>
                <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
                    <feGaussianBlur stdDeviation="4" result="blur" />
                    <feComposite in="SourceGraphic" in2="blur" operator="over" />
                </filter>
                <filter id="cutGlow" x="-30%" y="-30%" width="160%" height="160%">
                    <feGaussianBlur stdDeviation="3" result="blur" />
                    <feComposite in="SourceGraphic" in2="blur" operator="over" />
                </filter>
                <marker id="arrow" viewBox="0 0 10 10" refX="22" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                    <path d="M 0 1.5 L 10 5 L 0 8.5 z" fill="\(theme.edgeDefaultStroke)" />
                </marker>
                <marker id="arrowHighlight" viewBox="0 0 10 10" refX="22" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 1.5 L 10 5 L 0 8.5 z" fill="\(theme.edgeHighlightStroke)" />
                </marker>
                <marker id="arrowMatched" viewBox="0 0 10 10" refX="22" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 1.5 L 10 5 L 0 8.5 z" fill="#10b981" />
                </marker>
            </defs>

            <!-- Background Card -->
            <rect width="100%" height="100%" fill="url(#bgGrad)" rx="16" />

            <!-- Title Header -->
            <text x="32" y="44" fill="#f8fafc" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="20" font-weight="bold">\(escapeXML(vGraph.title))</text>
        """

        // ── Partitions Layer (Bipartite lanes) ──────────────────────────────────
        if !vGraph.partitions.isEmpty {
            svg += "\n\n    <!-- Partition Lanes Layer -->\n    <g id=\"partitions\">"
            let nodeMap = Dictionary(uniqueKeysWithValues: vGraph.nodes.map { ($0.id, $0) })
            for partition in vGraph.partitions {
                let memberNodes = partition.members.compactMap { nodeMap[$0] }
                guard !memberNodes.isEmpty else { continue }
                let minX = memberNodes.map { $0.x }.min()! - theme.nodeRadius - 24
                let maxX = memberNodes.map { $0.x }.max()! + theme.nodeRadius + 24
                let minY = memberNodes.map { $0.y }.min()! - theme.nodeRadius - 28
                let maxY = memberNodes.map { $0.y }.max()! + theme.nodeRadius + 20
                let pWidth = max(100.0, maxX - minX)
                let pHeight = max(100.0, maxY - minY)

                svg += """

                    <g class="partition-lane">
                        <rect x="\(minX)" y="\(minY)" width="\(pWidth)" height="\(pHeight)" rx="12" fill="\(partition.color)" fill-opacity="0.08" stroke="\(partition.color)" stroke-opacity="0.3" stroke-width="1" stroke-dasharray="4 4" />
                        <rect x="\(minX + 8)" y="\(minY - 10)" width="\(max(40.0, Double(partition.label.count) * 10.0 + 16.0))" height="20" rx="4" fill="#0f172a" stroke="\(partition.color)" stroke-width="1" />
                        <text x="\(minX + 16)" y="\(minY + 4)" fill="\(partition.color)" font-family="-apple-system, sans-serif" font-size="11" font-weight="bold">\(escapeXML(partition.label))</text>
                    </g>
                """
            }
            svg += "\n    </g>"
        }

        // ── Component Hulls Layer ───────────────────────────────────────────────
        if !vGraph.hulls.isEmpty {
            svg += "\n\n    <!-- Component Hulls Layer -->\n    <g id=\"hulls\">"
            let nodeMap = Dictionary(uniqueKeysWithValues: vGraph.nodes.map { ($0.id, $0) })
            for hull in vGraph.hulls {
                let memberNodes = hull.members.compactMap { nodeMap[$0] }
                guard !memberNodes.isEmpty else { continue }
                let minX = memberNodes.map { $0.x }.min()! - theme.nodeRadius - 16
                let maxX = memberNodes.map { $0.x }.max()! + theme.nodeRadius + 16
                let minY = memberNodes.map { $0.y }.min()! - theme.nodeRadius - 16
                let maxY = memberNodes.map { $0.y }.max()! + theme.nodeRadius + 16
                let hWidth = max(60.0, maxX - minX)
                let hHeight = max(60.0, maxY - minY)

                svg += """

                    <g class="hull">
                        <rect x="\(minX)" y="\(minY)" width="\(hWidth)" height="\(hHeight)" rx="14" fill="\(hull.fillColor)" fill-opacity="0.12" stroke="\(hull.strokeColor)" stroke-opacity="0.45" stroke-width="1.5" stroke-dasharray="5 5" />
                """
                if let label = hull.label, !label.isEmpty {
                    svg += """

                        <rect x="\(minX + 6)" y="\(minY - 9)" width="\(max(32.0, Double(label.count) * 8.5 + 12.0))" height="18" rx="4" fill="#0f172a" stroke="\(hull.strokeColor)" stroke-width="1" />
                        <text x="\(minX + 12)" y="\(minY + 3)" fill="\(hull.strokeColor)" font-family="-apple-system, sans-serif" font-size="10" font-weight="bold">\(escapeXML(label))</text>
                    """
                }
                svg += "\n    </g>"
            }
            svg += "\n    </g>"
        }

        // ── Edges Layer ─────────────────────────────────────────────────────────
        svg += "\n\n    <!-- Edges Layer -->\n    <g id=\"edges\">"

        for edge in vGraph.edges {
            let stroke: String
            let width: Double
            let filter: String
            let marker: String

            if edge.isMatched {
                stroke = "#10b981" // Emerald for matched edges
                width = 3.5
                filter = " filter=\"url(#glow)\""
                marker = vGraph.isDirected ? " marker-end=\"url(#arrowMatched)\"" : ""
            } else if edge.isHighlighted {
                stroke = theme.edgeHighlightStroke
                width = theme.edgeHighlightWidth
                filter = " filter=\"url(#glow)\""
                marker = vGraph.isDirected ? " marker-end=\"url(#arrowHighlight)\"" : ""
            } else {
                stroke = theme.edgeDefaultStroke
                width = theme.edgeStrokeWidth
                filter = ""
                marker = vGraph.isDirected ? " marker-end=\"url(#arrow)\"" : ""
            }

            if !edge.segments.isEmpty {
                // Render exact curved or line segments from layout engine
                var pathD = ""
                for segment in edge.segments {
                    switch segment {
                    case .line(let start, let end):
                        if pathD.isEmpty { pathD += "M \(start.x) \(start.y) " }
                        pathD += "L \(end.x) \(end.y) "
                    case .cubicCurve(let start, let c1, let c2, let end):
                        if pathD.isEmpty { pathD += "M \(start.x) \(start.y) " }
                        pathD += "C \(c1.x) \(c1.y), \(c2.x) \(c2.y), \(end.x) \(end.y) "
                    }
                }
                svg += """

                    <path d="\(pathD.trimmingCharacters(in: .whitespaces))" fill="none" stroke="\(stroke)" stroke-width="\(width)" stroke-linecap="round"\(filter)\(marker) />
                """
            } else if edge.waypoints.count >= 2 {
                let p1 = edge.waypoints[0]
                let p2 = edge.waypoints[edge.waypoints.count - 1]
                svg += """

                    <line x1="\(p1.x)" y1="\(p1.y)" x2="\(p2.x)" y2="\(p2.y)" stroke="\(stroke)" stroke-width="\(width)" stroke-linecap="round"\(filter)\(marker) />
                """
            }

            // Edge Cost / Attribute Label
            if let label = edge.label, !label.isEmpty {
                let midX: Double
                let midY: Double
                if let pos = edge.labelPosition {
                    midX = pos.x
                    midY = pos.y
                } else if edge.waypoints.count >= 2 {
                    let p1 = edge.waypoints[0]
                    let p2 = edge.waypoints[edge.waypoints.count - 1]
                    midX = (p1.x + p2.x) / 2.0
                    midY = (p1.y + p2.y) / 2.0 - 6.0
                } else {
                    midX = 0; midY = 0
                }

                let pillWidth = max(24.0, Double(label.count) * theme.edgeFontSize * 0.65 + 14.0)
                let pillHeight = theme.edgeFontSize + 8.0

                svg += """

                    <g class="edge-label">
                        <rect x="\(midX - pillWidth / 2.0)" y="\(midY - pillHeight / 2.0)" width="\(pillWidth)" height="\(pillHeight)" rx="4" fill="#0f172a" fill-opacity="0.92" stroke="\(stroke)" stroke-opacity="0.4" stroke-width="1" />
                        <text x="\(midX)" y="\(midY + theme.edgeFontSize * 0.35)" fill="\(theme.edgeTextColor)" font-family="-apple-system, sans-serif" font-size="\(theme.edgeFontSize)" font-weight="600" text-anchor="middle">\(escapeXML(label))</text>
                    </g>
                """
            }
        }
        svg += "\n    </g>"

        // ── Tour Step Badges Layer ──────────────────────────────────────────────
        if !vGraph.badges.isEmpty {
            svg += "\n\n    <!-- Tour Step Badges Layer -->\n    <g id=\"badges\">"
            for badge in vGraph.badges {
                svg += """

                    <g class="tour-badge" filter="url(#glow)">
                        <circle cx="\(badge.position.x)" cy="\(badge.position.y)" r="11" fill="\(badge.fillColor)" stroke="#ffffff" stroke-width="1.5" />
                        <text x="\(badge.position.x)" y="\(badge.position.y + 4.0)" fill="\(badge.textColor)" font-family="-apple-system, sans-serif" font-size="11" font-weight="bold" text-anchor="middle">\(badge.number)</text>
                    </g>
                """
            }
            svg += "\n    </g>"
        }

        // ── Nodes Layer ─────────────────────────────────────────────────────────
        svg += "\n\n    <!-- Nodes Layer -->\n    <g id=\"nodes\">"

        for node in vGraph.nodes {
            let fill = node.color ?? theme.nodeDefaultFill
            let stroke = node.isHighlighted ? theme.edgeHighlightStroke : theme.nodeStroke
            let strokeW = node.isHighlighted ? 3.0 : theme.nodeStrokeWidth
            let filter = node.isHighlighted ? " filter=\"url(#glow)\"" : ""

            svg += "\n        <g id=\"node-\(node.id)\">"

            // Cut-node (articulation point) warning diamond indicator
            if node.isCutNode {
                let d = theme.nodeRadius + 7.0
                svg += """

                    <polygon points="\(node.x),\(node.y - d) \(node.x + d),\(node.y) \(node.x),\(node.y + d) \(node.x - d),\(node.y)" fill="none" stroke="#f59e0b" stroke-width="2.0" stroke-dasharray="3 3" filter="url(#cutGlow)" />
                """
            }

            svg += """

                <circle cx="\(node.x)" cy="\(node.y)" r="\(theme.nodeRadius)" fill="\(fill)" stroke="\(stroke)" stroke-width="\(strokeW)"\(filter) />
                <text x="\(node.x)" y="\(node.y + theme.nodeFontSize * 0.38)" fill="\(theme.nodeTextColor)" font-family="-apple-system, sans-serif" font-size="\(theme.nodeFontSize)" font-weight="600" text-anchor="middle">\(escapeXML(node.label))</text>
            </g>
            """
        }

        svg += """

            </g>
        </svg>
        """

        return svg
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
