# Visualization Reference

## Overview

The `Visualization` module converts algorithm output from any `AdjacentGraph<V, W>` into a positioned, styled `VisualGraph` and renders it to standalone SVG markup. It works entirely inside the Swift package — no external dependencies are required.

**Source directory:** [`Sources/NetworkGraph/Visualization/`](Sources/NetworkGraph/Visualization/)

---

## Architecture

```
AdjacentGraph<V, W>
      │
      │  + highlight sets, edge labels, color maps
      ▼
  LayoutBridge                  ← assigns 2D (x, y) coordinates
      │   layoutSugiyama(...)   ← hierarchical layered layout
      │   layoutCircular(...)   ← circular arrangement
      ▼
  VisualGraph                   ← [VisualNode], [VisualEdge], size
      │
      ▼
  SVGGraphRenderer.renderToSVG  ← produces SVG string
      │
      ▼
  String (SVG markup)           ← write to file or embed in HTML
```

---

## `LayoutBridge`

**Source:** [`LayoutBridge.swift`](Sources/NetworkGraph/Visualization/LayoutBridge.swift)

Converts a graph + algorithm result annotations into a fully-positioned `VisualGraph`.

### Sugiyama Hierarchical Layout

Best for directed graphs, DAGs, and flow networks. Assigns vertices to horizontal layers based on longest-path rank assignment, then positions them symmetrically within each layer.

```swift
let vGraph = LayoutBridge.layoutSugiyama(
    graph: myGraph,
    title: "Minimum Spanning Tree",
    highlightEdges: Set(mst.edges),      // drawn with glow stroke
    highlightNodes: Set([source, sink]),  // drawn with highlighted ring
    nodeColors: [0: "#f43f5e", 1: "#10b981"],  // per-vertex fill override
    edgeLabels: [Edge(u:0, v:1): "12"],         // mid-edge annotation
    theme: .modernDark
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `graph` | `AdjacentGraph<V, W>` | — | Input graph |
| `title` | `String` | `"Graph Layout"` | Caption shown in SVG header |
| `highlightEdges` | `Set<Edge>` | `[]` | Edges drawn with glowing accent stroke |
| `highlightNodes` | `Set<Int>` | `[]` | Vertices drawn with accent ring |
| `nodeColors` | `[Int: String]` | `[:]` | Per-vertex CSS hex fill (overrides theme default) |
| `edgeLabels` | `[Edge: String]` | `[:]` | Labels drawn on edge midpoints |
| `theme` | `GraphVisualTheme` | `.modernDark` | Color and sizing theme |

### Circular Layout

Best for Hamiltonian cycles, TSP tours, regular graphs, and social networks. Places all vertices evenly around a circle at a configurable radius.

```swift
let vGraph = LayoutBridge.layoutCircular(
    graph: myGraph,
    title: "TSP Optimal Tour",
    tour: tsp.tour,               // sequential vertex order → highlighted edges
    highlightEdges: [],
    theme: .modernDark
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `graph` | `AdjacentGraph<V, W>` | — | Input graph |
| `title` | `String` | `"Circular Layout"` | Caption shown in SVG header |
| `tour` | `[Int]?` | `nil` | Ordered vertex sequence defining a highlighted route |
| `highlightEdges` | `Set<Edge>` | `[]` | Additional edges to highlight |
| `theme` | `GraphVisualTheme` | `.modernDark` | Theme |

---

## `VisualGraph`

The intermediate data model holding positioned nodes and routed edges. Can be post-processed before rendering.

```swift
public struct VisualGraph: Sendable {
    public var title: String
    public var nodes: [VisualNode]
    public var edges: [VisualEdge]
    public var width: Double
    public var height: Double
}
```

### `VisualNode`

```swift
public struct VisualNode: Sendable {
    public let id: Int
    public var label: String
    public var x: Double
    public var y: Double
    public var color: String?        // CSS hex fill; nil = theme default
    public var isHighlighted: Bool
}
```

### `VisualEdge`

```swift
public struct VisualEdge: Sendable {
    public let from: Int
    public let to: Int
    public var label: String?
    public var isHighlighted: Bool
    public var sequenceNumber: Int?  // for TSP / postman step ordering
    public var waypoints: [VisualPoint]  // [start, ..., end] for curve routing
}
```

---

## `SVGGraphRenderer`

**Source:** [`SVGGraphRenderer.swift`](Sources/NetworkGraph/Visualization/SVGGraphRenderer.swift)

Produces self-contained, responsive SVG markup. The output is a single `<svg>` element and can be:
- Written to a `.svg` file and opened in any browser or vector editor
- Embedded directly in HTML (`<div>` wrapper)
- Imported into Sketch, Figma, or Illustrator

```swift
let svgString = SVGGraphRenderer.renderToSVG(vGraph, theme: .modernDark)
try svgString.write(toFile: "output.svg", atomically: true, encoding: .utf8)
```

### SVG Features

| Feature | Description |
|---|---|
| **Viewport** | `viewBox` scales to content; responsive `width="100%"` |
| **Background** | Linear gradient from `#0f172a` to `#020617` (dark theme) |
| **Nodes** | Filled circles with label, stroke ring, glow filter on highlighted nodes |
| **Edges** | Straight lines with directional arrow markers; glow filter on highlighted edges |
| **Edge Labels** | Floating pill labels (`<rect>` + `<text>`) at edge midpoints |
| **Glow Effect** | `<feGaussianBlur>` + `<feComposite>` SVG filter for neon highlights |
| **Arrow Markers** | Separate `<marker>` elements for default and highlighted arrows |

---

## `GraphVisualTheme`

**Source:** [`GraphVisualTheme.swift`](Sources/NetworkGraph/Visualization/GraphVisualTheme.swift)

All rendering parameters in one struct. Two pre-built themes:

### `GraphVisualTheme.modernDark` (default)

Dark slate background with neon blue/rose accents — optimized for presentations and dark-mode UIs.

| Property | Value |
|---|---|
| `nodeDefaultFill` | `#1e293b` |
| `nodeStroke` | `#38bdf8` (sky blue) |
| `edgeDefaultStroke` | `#64748b` (slate) |
| `edgeHighlightStroke` | `#f43f5e` (rose) |
| Color palette | Sky blue, Rose, Emerald, Purple, Amber, Pink, Cyan, Lime |

### `GraphVisualTheme.standardLight`

Clean white cards with blue/red accents — optimized for academic papers and light-mode documents.

### Custom Theme

```swift
var custom = GraphVisualTheme.modernDark
custom.nodeRadius = 22
custom.nodeFontSize = 14
custom.edgeHighlightStroke = "#a855f7"  // purple highlights
custom.palette = ["#3b82f6", "#6366f1", "#8b5cf6", "#d946ef"]
```

---

## Workflow Examples

### Flow Network with Saturated Arc Highlights

```swift
let (maxFlow, solvedNet) = AdvancedFlow.dinicMaxFlow(in: net, from: 0, to: n-1)

var edgeLabels: [Edge: String] = [:]
var highlightEdges = Set<Edge>()
for e in solvedNet.edges {
    if let attr = solvedNet.edgeProperties[e] {
        edgeLabels[e] = "\(Int(attr.flow))/\(Int(attr.capacity))"
        if attr.flow > 0 { highlightEdges.insert(e) }
    }
}

let vGraph = LayoutBridge.layoutSugiyama(
    graph: solvedNet,
    title: "Max Flow = \(maxFlow)",
    highlightEdges: highlightEdges,
    edgeLabels: edgeLabels
)
let svg = SVGGraphRenderer.renderToSVG(vGraph)
```

### Vertex Coloring with Color-Coded Nodes

```swift
let coloring = GraphColoring.color(graph)
let theme = GraphVisualTheme.modernDark
var nodeColors: [Int: String] = [:]
for (v, c) in coloring.colors {
    nodeColors[v] = theme.palette[c % theme.palette.count]
}

let vGraph = LayoutBridge.layoutSugiyama(
    graph: graph,
    title: "χ(G) = \(coloring.chromaticNumber)",
    nodeColors: nodeColors
)
```

### TSP / Hamilton Tour on Circular Layout

```swift
let tsp = PathsAndCycles.travelingSalesman(graph: completeGraph)

let vGraph = LayoutBridge.layoutCircular(
    graph: completeGraph,
    title: "TSP Tour (cost: \(tsp.totalCost))",
    tour: tsp.tour
)
```

### Minimum Spanning Tree with Weight Labels

```swift
let mst = Connectivity.minimumSpanningTree(graph: weightedGraph)
var edgeLabels: [Edge: String] = [:]
for e in weightedGraph.edges {
    if let w = weightedGraph.edgeProperties[e] {
        edgeLabels[e] = "\(Int(w))"
    }
}

let vGraph = LayoutBridge.layoutSugiyama(
    graph: weightedGraph,
    title: "MST (weight: \(mst.totalWeight))",
    highlightEdges: Set(mst.edges),
    edgeLabels: edgeLabels
)
```

---

## CLI Integration

The `net` CLI tool wraps all of the above into named subcommands with `--output <file.svg>` flags:

```bash
# All SVG exports use the same LayoutBridge + SVGGraphRenderer pipeline
swift run net mst   --vertices 8 --output mst.svg
swift run net tsp   --cities 7   --output tsp.svg
swift run net flow  --vertices 6 --output flow.svg
swift run net color --vertices 9 --output color.svg
swift run net match --size 4     --output match.svg
```
