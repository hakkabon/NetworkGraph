//
//  SVGGraphRenderer.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Renders a `VisualGraph` into vector SVG markup.
public enum SVGGraphRenderer {

    /// Generates standalone, responsive SVG markup for the given `VisualGraph`.
    public static func renderToSVG(_ vGraph: VisualGraph, theme: GraphVisualTheme = .modernDark) -> String {
        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(Int(vGraph.width)) \(Int(vGraph.height))" width="100%" height="100%">
            <defs>
                <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stop-color="#0f172a" />
                    <stop offset="100%" stop-color="#020617" />
                </linearGradient>
                <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
                    <feGaussianBlur stdDeviation="4" result="blur" />
                    <feComposite in="SourceGraphic" in2="blur" operator="over" />
                </filter>
                <marker id="arrow" viewBox="0 0 10 10" refX="22" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                    <path d="M 0 1.5 L 10 5 L 0 8.5 z" fill="\(theme.edgeDefaultStroke)" />
                </marker>
                <marker id="arrowHighlight" viewBox="0 0 10 10" refX="22" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 1.5 L 10 5 L 0 8.5 z" fill="\(theme.edgeHighlightStroke)" />
                </marker>
            </defs>

            <!-- Background Card -->
            <rect width="100%" height="100%" fill="url(#bgGrad)" rx="16" />

            <!-- Title Header -->
            <text x="32" y="44" fill="#f8fafc" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="20" font-weight="bold">\(vGraph.title)</text>

            <!-- Edges Layer -->
            <g id="edges">
        """

        for edge in vGraph.edges {
            guard edge.waypoints.count >= 2 else { continue }
            let p1 = edge.waypoints[0]
            let p2 = edge.waypoints[edge.waypoints.count - 1]

            let stroke = edge.isHighlighted ? theme.edgeHighlightStroke : theme.edgeDefaultStroke
            let width = edge.isHighlighted ? theme.edgeHighlightWidth : theme.edgeStrokeWidth
            let filter = edge.isHighlighted ? " filter=\"url(#glow)\"" : ""
            let marker = edge.isHighlighted ? " marker-end=\"url(#arrowHighlight)\"" : " marker-end=\"url(#arrow)\""

            svg += """

                <line x1="\(p1.x)" y1="\(p1.y)" x2="\(p2.x)" y2="\(p2.y)" stroke="\(stroke)" stroke-width="\(width)" stroke-linecap="round"\(filter)\(marker) />
            """

            if let label = edge.label, !label.isEmpty {
                let midX = (p1.x + p2.x) / 2.0
                let midY = (p1.y + p2.y) / 2.0 - 8.0
                svg += """

                <rect x="\(midX - 16)" y="\(midY - 10)" width="32" height="16" rx="4" fill="#0f172a" fill-opacity="0.85" />
                <text x="\(midX)" y="\(midY + 2)" fill="\(theme.edgeTextColor)" font-family="-apple-system, sans-serif" font-size="\(theme.edgeFontSize)" text-anchor="middle">\(label)</text>
                """
            }
        }

        svg += """

            </g>

            <!-- Nodes Layer -->
            <g id="nodes">
        """

        for node in vGraph.nodes {
            let fill = node.color ?? theme.nodeDefaultFill
            let stroke = node.isHighlighted ? theme.edgeHighlightStroke : theme.nodeStroke
            let strokeW = node.isHighlighted ? 3.0 : theme.nodeStrokeWidth
            let filter = node.isHighlighted ? " filter=\"url(#glow)\"" : ""

            svg += """

                <g id="node-\(node.id)">
                    <circle cx="\(node.x)" cy="\(node.y)" r="\(theme.nodeRadius)" fill="\(fill)" stroke="\(stroke)" stroke-width="\(strokeW)"\(filter) />
                    <text x="\(node.x)" y="\(node.y + 4.5)" fill="\(theme.nodeTextColor)" font-family="-apple-system, sans-serif" font-size="\(theme.nodeFontSize)" font-weight="600" text-anchor="middle">\(node.label)</text>
                </g>
            """
        }

        svg += """

            </g>
        </svg>
        """

        return svg
    }
}
