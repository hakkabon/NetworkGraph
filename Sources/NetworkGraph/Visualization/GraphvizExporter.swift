import Foundation

// MARK: - Graphviz DOT exporter

/// Generates a Graphviz DOT description of a graph that can be piped to the
/// `dot` command-line tool (Graphviz must be installed on the host).
///
/// Usage:
/// ```swift
/// let dot = GraphvizExporter.dot(graph: g, title: "TSP", tour: tsp.tour)
/// try GraphvizExporter.renderPDF(dot: dot, outputPath: "tour.pdf")
/// ```
public enum GraphvizExporter {

    // MARK: Public API

    /// Generates a DOT-language description of the graph.
    ///
    /// - Parameters:
    ///   - graph: The source graph.
    ///   - title: Graph label shown in the rendered output.
    ///   - tour: Optional ordered vertex sequence; tour edges are highlighted red and
    ///           labelled with their step number.
    ///   - highlightEdges: Additional edge set to draw in a highlight colour.
    ///   - edgeLabels: Custom per-edge labels (weights/costs). If empty the exporter
    ///                 auto-extracts numeric properties from the graph.
    ///   - nodeColors: Optional per-vertex fill colours (HTML hex strings).
    public static func dot<V, W>(
        graph: AdjacentGraph<V, W>,
        title: String = "Graph",
        tour: [Int]? = nil,
        highlightEdges: Set<Edge> = [],
        edgeLabels: [Edge: String] = [:],
        nodeColors: [Int: String] = [:]
    ) -> String {
        let directed = graph.kind == .directed
        let graphKw  = directed ? "digraph" : "graph"
        let edgeOp   = directed ? "->" : "--"

        // Build tour step map: edge -> step number (1-based)
        var tourSteps: [Edge: Int] = [:]
        if let tour {
            for (step, pair) in zip(tour, tour.dropFirst()).enumerated() {
                let e = Edge(u: pair.0, v: pair.1)
                tourSteps[e] = step + 1
                if !directed { tourSteps[e.reversed()] = step + 1 }
            }
        }

        // Effective labels
        let labels = edgeLabels.isEmpty ? LayoutBridge.defaultEdgeLabels(for: graph) : edgeLabels

        var lines: [String] = []
        lines.append("\(graphKw) \"\(title.replacingOccurrences(of: "\"", with: "'"))\" {")
        lines.append("    graph [fontname=\"Helvetica\" label=\"\(title.replacingOccurrences(of: "\"", with: "'"))\" labelloc=t]")
        lines.append("    node  [fontname=\"Helvetica\" shape=circle style=filled fillcolor=\"#1e293b\" fontcolor=white color=\"#475569\"]")
        lines.append("    edge  [fontname=\"Helvetica\" color=\"#64748b\" fontcolor=\"#94a3b8\"]")
        lines.append("")

        // Nodes
        for v in 0..<graph.vertexCount {
            var attrs: [String] = ["label=\"\(v)\""]
            if let color = nodeColors[v] {
                attrs.append("fillcolor=\"\(color)\"")
            }
            if let t = tour, t.dropLast().contains(v) {
                attrs.append("color=\"#f43f5e\"")
            }
            lines.append("    \(v) [\(attrs.joined(separator: " "))]")
        }
        lines.append("")

        // Edges (deduplicate undirected)
        var seen = Set<Edge>()
        for edge in graph.edges {
            let key = (!directed && edge.u > edge.v) ? edge.reversed() : edge
            if !directed && !seen.insert(key).inserted { continue }

            var attrs: [String] = []

            // Cost label
            let costLabel = labels[key] ?? (!directed ? labels[key.reversed()] : nil)
            if let costLabel { attrs.append("label=\"\(costLabel)\"") }

            // Tour overlay
            if let step = tourSteps[key] ?? (!directed ? tourSteps[key.reversed()] : nil) {
                attrs.append("color=\"#f43f5e\"")
                attrs.append("penwidth=2.5")
                attrs.append("fontcolor=\"#f43f5e\"")
                // Prepend step number to the label
                let base = costLabel.map { " (\($0))" } ?? ""
                // Replace or add label with "step: cost"
                if let idx = attrs.firstIndex(where: { $0.hasPrefix("label=") }) {
                    attrs[idx] = "label=\"\(step)\(base)\""
                } else {
                    attrs.append("label=\"\(step)\"")
                }
            } else if highlightEdges.contains(key) || (!directed && highlightEdges.contains(key.reversed())) {
                attrs.append("color=\"#22d3ee\"")
                attrs.append("penwidth=2.0")
            }

            let attrStr = attrs.isEmpty ? "" : " [\(attrs.joined(separator: " "))]"
            lines.append("    \(key.u) \(edgeOp) \(key.v)\(attrStr)")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: Shell rendering

    /// Renders a DOT string to a file using the system `dot` binary.
    ///
    /// - Parameters:
    ///   - dot: The DOT-language string.
    ///   - outputPath: Destination file path. The format is inferred from the extension
    ///                 (`.pdf`, `.png`, `.svg`). Defaults to PDF.
    ///   - open: Whether to open the rendered file with the default system viewer.
    ///
    /// - Throws: `GraphvizExporterError` if `dot` is not found or exits with an error.
    public static func render(dot: String, to outputPath: String, open openAfter: Bool = true) throws {
        // Infer format from extension
        let ext = (outputPath as NSString).pathExtension.lowercased()
        let format: String
        switch ext {
        case "svg": format = "svg"
        case "png": format = "png"
        case "jpg", "jpeg": format = "jpg"
        default: format = "pdf"
        }

        // Locate dot binary
        guard let dotBin = findDotBinary() else {
            throw GraphvizExporterError.dotNotFound
        }

        // Write DOT to a temp file
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("networkgraph_\(Int.random(in: 100000...999999)).dot")
        try dot.write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        // Run: dot -T<format> <tmp.dot> -o <outputPath>
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dotBin)
        process.arguments = ["-T\(format)", tmp.path, "-o", outputPath]

        let errPipe = Pipe()
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errMsg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "(no output)"
            throw GraphvizExporterError.dotFailed(errMsg)
        }

        if openAfter {
            let openProc = Process()
            openProc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openProc.arguments = [outputPath]
            try? openProc.run()
            openProc.waitUntilExit()
        }
    }

    // MARK: Helpers

    private static func findDotBinary() -> String? {
        let candidates = ["/usr/local/bin/dot", "/opt/homebrew/bin/dot", "/usr/bin/dot"]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            return path
        }
        // Try PATH via which
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = ["dot"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (out?.isEmpty == false) ? out : nil
    }
}

// MARK: - Errors

public enum GraphvizExporterError: Error, LocalizedError {
    case dotNotFound
    case dotFailed(String)

    public var errorDescription: String? {
        switch self {
        case .dotNotFound:
            return "Graphviz 'dot' binary not found. Install via: brew install graphviz"
        case .dotFailed(let msg):
            return "dot exited with error: \(msg)"
        }
    }
}

// MARK: - Convenience on VisualGraph

public extension VisualGraph {
    /// Returns a DOT-language string describing this visual graph.
    /// Passes through node positions, highlighted edges, and tour badges
    /// that were already computed by the layout engine.
    var graphvizDOT: String {
        let directed = isDirected
        let graphKw  = directed ? "digraph" : "graph"
        let edgeOp   = directed ? "->" : "--"

        var lines: [String] = []
        lines.append("\(graphKw) \"\(title.replacingOccurrences(of: "\"", with: "'"))\" {")
        lines.append("    graph [fontname=\"Helvetica\" label=\"\(title.replacingOccurrences(of: "\"", with: "'"))\" labelloc=t layout=neato]")
        lines.append("    node  [fontname=\"Helvetica\" shape=circle style=filled fillcolor=\"#1e293b\" fontcolor=white color=\"#475569\" width=0.5]")
        lines.append("    edge  [fontname=\"Helvetica\" color=\"#64748b\" fontcolor=\"#94a3b8\"]")
        lines.append("")

        // Nodes with fixed positions (neato pos attribute, pts scaled down)
        let scale = 1.0 / 72.0  // pt per pixel approx
        for node in nodes {
            var attrs: [String] = [
                "label=\"\(node.label)\"",
                "pos=\"\(String(format: "%.2f", node.x * scale)),\(String(format: "%.2f", node.y * scale))!\""
            ]
            if node.isCutNode { attrs.append("color=\"#f59e0b\"") }
            if node.isHighlighted { attrs.append("fillcolor=\"#22d3ee\"") }
            if let color = node.color { attrs.append("fillcolor=\"\(color)\"") }
            lines.append("    \(node.id) [\(attrs.joined(separator: " "))]")
        }
        lines.append("")

        // Edges
        for edge in edges {
            var attrs: [String] = []
            if let lbl = edge.label { attrs.append("label=\"\(lbl)\"") }
            if edge.isHighlighted || edge.sequenceNumber != nil {
                attrs.append("color=\"#f43f5e\"")
                attrs.append("penwidth=2.5")
                attrs.append("fontcolor=\"#f43f5e\"")
            }
            if let seq = edge.sequenceNumber {
                // Prepend step number to label
                if let idx = attrs.firstIndex(where: { $0.hasPrefix("label=") }),
                   let lbl = edge.label {
                    attrs[idx] = "label=\"\(seq): \(lbl)\""
                } else {
                    attrs.append("label=\"\(seq)\"")
                }
            }
            let attrStr = attrs.isEmpty ? "" : " [\(attrs.joined(separator: " "))]"
            lines.append("    \(edge.from) \(edgeOp) \(edge.to)\(attrStr)")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }
}
