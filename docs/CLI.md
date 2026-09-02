# `net` CLI Reference

## Overview

The `net` executable is a command-line interface for solving combinatorial graph problems and exporting vector SVG visualizations directly from the terminal.

**Build & run:**
```bash
swift build -c release
.build/release/net --help
```

Or directly via SwiftPM:
```bash
swift run net <subcommand> [options]
```

---

## Subcommands

| Subcommand | Topic | Description |
|---|---|---|
| `random` | 1.1 – 1.10 | Generate random graphs with edge costs and SVG export |
| `mst` | 2.10 | Compute Minimum Spanning Tree with highlighted edges and costs |
| `tsp` | 3.12 | Solve Traveling Salesman Problem with tour sequence badges and costs |
| `euler` | 3.9 | Compute Eulerian Circuit/Trail with step badges |
| `postman` | 3.11 | Solve Chinese Postman Problem with route costs and badges |
| `sp` | 3.3 | Compute Shortest Path via Bidirectional Dijkstra |
| `flow` | 8.1 | Compute Maximum Network Flow (Dinic) with flow/capacity labels |
| `color` | 6.1 | Vertex Coloring & Chromatic Number |
| `match` | 7.1 | Maximum Bipartite Matching with rank-pinned partitions |
| `planar` | 4.1 | Planarity Test |

---

## `net random`

Generates a random graph of a given topology type and optionally exports a visualization.

```
USAGE: net random [--type <type>] [--vertices <n>] [--edges <m>] [--output <path>]

OPTIONS:
  -t, --type <type>       Graph type: general, bipartite, regular, tree, hamilton, flow
                          (default: general)
  -v, --vertices <n>      Number of vertices (default: 8)
  -e, --edges <m>         Number of edges (default: 12)
  -o, --output <path>     Output SVG file path (optional)
```

**Examples:**
```bash
# Random connected graph, 10 vertices, 18 edges → exported to SVG
swift run net random --type general --vertices 10 --edges 18 --output graph.svg

# Random bipartite graph
swift run net random --type bipartite --vertices 8 --output bip.svg

# Random flow network
swift run net random --type flow --vertices 6 --output flow_net.svg

# Random 3-regular graph
swift run net random --type regular --vertices 10 --output regular.svg
```

---

## `net mst`

Generates a random weighted connected graph and computes its Minimum Spanning Tree using Kruskal's algorithm.

```
USAGE: net mst [--vertices <n>] [--edges <m>] [--output <path>]

OPTIONS:
  -v, --vertices <n>      Number of vertices (default: 8)
  -e, --edges <m>         Number of edges (default: 14)
  -o, --output <path>     Output SVG file path (optional)
```

**Output:**
- Total MST weight printed to stdout
- MST edges listed to stdout
- SVG with MST edges highlighted in rose and edge weight labels shown

**Example:**
```bash
swift run net mst --vertices 10 --edges 20 --output mst.svg
# 🌲 Minimum Spanning Tree Total Weight: 32.0
#    Edges in MST: [0 → 3, 1 → 5, ...]

# Also render as PDF via Graphviz
swift run net mst --vertices 10 --edges 20 --graphviz mst.pdf
# 📐 DOT source written to mst.pdf.dot
# 🖼️ Graphviz render opened: mst.pdf
```

---

## `net tsp`

Generates a complete weighted graph on `n` cities and solves the Traveling Salesman Problem using Held-Karp exact DP (small $n$) with 2-opt refinement.

```
USAGE: net tsp [--cities <n>] [--output <path>] [--graphviz <path>]

OPTIONS:
  -c, --cities <n>        Number of cities (default: 6)
  -o, --output <path>     Output SVG file path (optional)
      --graphviz <path>   Output Graphviz PDF/PNG/SVG file; also writes a .dot
                          alongside it (requires 'dot' from Graphviz)
```

**Output:**
- Optimal tour vertex sequence printed to stdout
- Total travel cost printed to stdout
- SVG: tour edges highlighted on a circular layout with step badges and cost labels
- DOT/PDF: edges labelled `"<step>: <cost>"` in red; non-tour edges in grey

**Example:**
```bash
# SVG circular layout
swift run net tsp --cities 7 --output tsp.svg
# 🚀 Optimal TSP Tour: [0, 4, 2, 6, 3, 1, 5, 0]
# 💰 Total Travel Cost: 87.0

# Graphviz PDF (also saves tsp.pdf.dot)
swift run net tsp --cities 7 --graphviz tsp.pdf

# Both at once
swift run net tsp --cities 5 --output tsp.svg --graphviz tsp.pdf
```

---

## `net flow`

Generates a random layered flow network and computes maximum flow using Dinic's blocking flow algorithm.

```
USAGE: net flow [--vertices <n>] [--output <path>]

OPTIONS:
  -v, --vertices <n>      Number of vertices (default: 6)
  -o, --output <path>     Output SVG file path (optional)
```

**Output:**
- Maximum flow value printed to stdout
- SVG with arc flow labels `flow/capacity` and saturated arcs highlighted

**Example:**
```bash
swift run net flow --vertices 8 --output flow.svg
# 🌊 Maximum Network Flow (Dinic): 14.0
#    Exported visualization to flow.svg
```

---

## `net color`

Generates a random connected graph and computes the chromatic number $\chi(G)$ using DSatur vertex coloring.

```
USAGE: net color [--vertices <n>] [--edges <m>] [--output <path>]

OPTIONS:
  -v, --vertices <n>      Number of vertices (default: 8)
  -e, --edges <m>         Number of edges (default: 12)
  -o, --output <path>     Output SVG file path (optional)
```

**Output:**
- Chromatic number $\chi(G)$ printed to stdout
- Color class partition printed to stdout
- SVG with each color class in a distinct theme palette color

**Example:**
```bash
swift run net color --vertices 10 --edges 18 --output color.svg
# 🎨 Chromatic Number χ(G): 3
#    Color Classes: [[0, 2, 5], [3, 7, 9], [1, 4, 6, 8]]
#    Exported visualization to color.svg
```

---

## `net match`

Generates a random bipartite graph and computes a maximum cardinality matching using Hopcroft-Karp.

```
USAGE: net match [--size <n>] [--output <path>]

OPTIONS:
  -s, --size <n>          Size of each partition (default: 4)
  -o, --output <path>     Output SVG file path (optional)
```

**Output:**
- Matching cardinality and matched edge pairs printed to stdout
- SVG with matched edges highlighted

**Example:**
```bash
swift run net match --size 5 --output match.svg
# 🤝 Maximum Bipartite Matching: 4 pairs
#    Matched Edges: [0 → 6, 1 → 8, 3 → 7, 4 → 9]
#    Exported visualization to match.svg
```

---

## `net planar`

Tests whether a random graph is planar using the Hopcroft-Tarjan algorithm.

```
USAGE: net planar [--vertices <n>] [--edges <m>]

OPTIONS:
  -v, --vertices <n>      Number of vertices (default: 5)
  -e, --edges <m>         Number of edges (default: 10)
```

**Example:**
```bash
swift run net planar --vertices 5 --edges 9
# 🗺️ Is Planar: YES ✅

swift run net planar --vertices 5 --edges 10
# 🗺️ Is Planar: NO ❌
```

> **Note:** $K_5$ (5 vertices, 10 edges, complete) is the smallest non-planar complete graph.

---

## SVG Output Format

All subcommands with `--output` produce self-contained `.svg` files:
- Viewable in any browser (open with `open *.svg` on macOS)
- Importable into Figma, Sketch, Adobe Illustrator
- Embeddable in HTML: `<img src="graph.svg">` or inline `<svg>...</svg>`
- Scalable to any resolution (vector, not raster)

```bash
# Generate and immediately open in browser
swift run net mst --vertices 12 --output mst.svg && open mst.svg
```

---

## Graphviz Output Format

The following subcommands also support `--graphviz <path>` for DOT-format rendering via Graphviz:
`mst`, `tsp`, `euler`, `postman`, `sp`

```
--graphviz <path>    Output path for the rendered file (.pdf, .png, .svg)
                     A companion .dot source file is always written alongside it.
                     Requires Graphviz to be installed: brew install graphviz
```

**What gets rendered:**
- Tour/solution edges highlighted in **red** (`color="#f43f5e"`, `penwidth=2.5`)
- Each tour edge labelled `"<step>: <cost>"` e.g. `"3: 15"` = step 3, cost 15
- Non-tour edges in grey with just the cost label
- Tour vertices outlined in red
- Non-tour vertices in dark slate

**Example (TSP):**
```bash
swift run net tsp --cities 6 --graphviz tsp.pdf
# 🚀 Optimal TSP Tour: [0, 2, 4, 3, 1, 5, 0]
# 💰 Total Travel Cost: 72.0
# 📐 DOT source written to tsp.pdf.dot
# 🖼️ Graphviz render opened: tsp.pdf
```

**Manual rendering from saved DOT:**
```bash
dot -Tpdf tsp.pdf.dot -o tsp.pdf
dot -Tsvg tsp.pdf.dot -o tsp.svg
dot -Tpng tsp.pdf.dot -o tsp.png
```

**From code using `GraphvizExporter`:**
```swift
import NetworkGraph

// Generate DOT string
let dot = GraphvizExporter.dot(graph: g, title: "My Tour", tour: tsp.tour)

// Render and open
try GraphvizExporter.render(dot: dot, to: "tour.pdf", open: true)

// Or from a VisualGraph directly (includes layout positions)
let vGraph = LayoutBridge.layoutCircular(graph: g, tour: tsp.tour)
let dot = vGraph.graphvizDOT
try dot.write(toFile: "tour.dot", atomically: true, encoding: .utf8)
```

**Format inference:** The output format is inferred from the file extension. Supported: `.pdf` (default), `.svg`, `.png`, `.jpg`.

