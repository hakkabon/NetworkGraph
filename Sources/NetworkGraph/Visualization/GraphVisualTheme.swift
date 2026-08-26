//
//  GraphVisualTheme.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Visual styling configuration for rendering graphs and optimization results.
public struct GraphVisualTheme: Sendable {
    public var nodeRadius: Double
    public var nodeDefaultFill: String
    public var nodeStroke: String
    public var nodeStrokeWidth: Double
    public var nodeTextColor: String
    public var nodeFontSize: Double

    public var edgeDefaultStroke: String
    public var edgeHighlightStroke: String
    public var edgeStrokeWidth: Double
    public var edgeHighlightWidth: Double
    public var edgeTextColor: String
    public var edgeFontSize: Double

    /// Color palette for node coloring classes and connected components.
    public var palette: [String]

    public static let modernDark = GraphVisualTheme(
        nodeRadius: 18.0,
        nodeDefaultFill: "#1e293b",
        nodeStroke: "#38bdf8",
        nodeStrokeWidth: 2.0,
        nodeTextColor: "#f8fafc",
        nodeFontSize: 12.0,
        edgeDefaultStroke: "#64748b",
        edgeHighlightStroke: "#f43f5e",
        edgeStrokeWidth: 1.5,
        edgeHighlightWidth: 3.5,
        edgeTextColor: "#cbd5e1",
        edgeFontSize: 11.0,
        palette: [
            "#38bdf8", // Sky blue
            "#f43f5e", // Rose
            "#10b981", // Emerald
            "#a855f7", // Purple
            "#f59e0b", // Amber
            "#ec4899", // Pink
            "#06b6d4", // Cyan
            "#84cc16"  // Lime
        ]
    )

    public static let standardLight = GraphVisualTheme(
        nodeRadius: 18.0,
        nodeDefaultFill: "#ffffff",
        nodeStroke: "#0284c7",
        nodeStrokeWidth: 2.0,
        nodeTextColor: "#0f172a",
        nodeFontSize: 12.0,
        edgeDefaultStroke: "#94a3b8",
        edgeHighlightStroke: "#e11d48",
        edgeStrokeWidth: 1.5,
        edgeHighlightWidth: 3.5,
        edgeTextColor: "#475569",
        edgeFontSize: 11.0,
        palette: [
            "#0284c7",
            "#e11d48",
            "#059669",
            "#7c3aed",
            "#d97706",
            "#db2777",
            "#0891b2",
            "#65a30d"
        ]
    )
}
