# NetworkGraph

A comprehensive, high-performance, protocol-driven Swift package for **combinatorial optimization**, advanced graph algorithms, and vector graph visualization — from Hamiltonian cycles and max-flow networks to chromatic polynomials and exact cover problems.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2014%2B%20%7C%20iOS%2016%2B-blue.svg)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-130%20passed%20%2F%200%20failed-brightgreen.svg)](Tests/)

---

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Combinatorial Optimization Suite](#combinatorial-optimization-suite)
  - [1. Random Graph Generation](#1-random-graph-generation)
  - [2. Connectivity](#2-connectivity)
  - [3. Paths and Cycles](#3-paths-and-cycles)
  - [4. Planarity Testing](#4-planarity-testing)
  - [5. Graph Isomorphism](#5-graph-isomorphism)
  - [6. Coloring](#6-coloring)
  - [7. Graph Matching](#7-graph-matching)
  - [8. Network Flow](#8-network-flow)
  - [9. Packing and Covering](#9-packing-and-covering)
- [Foundational ADTs](#foundational-adts)
- [Visualization & Layout Bridge](#visualization--layout-bridge)
- [CLI (`net`)](#cli-net)
- [Core Architecture](#core-architecture)
  - [Graph Protocols](#graph-protocols)
  - [Vertex Types](#vertex-types)
  - [Edge Types](#edge-types)
  - [Graph Construction](#graph-construction)
  - [Property Access](#property-access)
- [Network Flow](#classic-network-flow-ford-fulkerson)
- [File Import](#file-import)
- [Installation](#installation)
- [Testing](#testing)
- [Documentation](#documentation)
- [License](#license)

---

## Overview

`NetworkGraph` provides a single generic graph container — `AdjacentGraph<V, W>` — built on a layered protocol hierarchy inspired by the [Boost Graph Library](https://www.boost.org/doc/libs/release/libs/graph/). It separates structural topology from vertex/edge payloads and delivers production-grade implementations of algorithms across the full spectrum of combinatorial optimization.

**What's new in this release:**
- **9 algorithm domains** covering random generation, connectivity, paths & cycles, planarity, isomorphism, coloring, matching, network flow, and packing/covering — over 50 individual algorithms
- **Foundational ADTs**: `DisjointSet` (Union-Find) and `BitVector` used throughout the combinatorial algorithms
- **Vector visualization engine**: Sugiyama hierarchical and circular layout with rich SVG export including path highlights, flow labels, color-coded nodes, and themes
- **`net` CLI tool**: 7 subcommands to run algorithms and export `.svg` visualizations from the terminal

---

## Quick Start

```swift
import NetworkGraph

// Create a directed weighted graph
var g = AdjacentGraph<String, Double>(vertices: ["A", "B", "C", "D"])
_ = g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.5
_ = g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 2.0
_ = g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 0.5
_ = g.addEdge(u: 0, v: 3); g[Edge(u: 0, v: 3)] = 5.0

// Shortest path (Bidirectional Dijkstra)
let sp = PathsAndCycles.bidirectionalDijkstra(graph: g, source: 0, target: 3)
print(sp.distance)  // 4.0 (via A→B→C→D)

// Minimum Spanning Tree
let mst = Connectivity.minimumSpanningTree(graph: g)
print(mst.totalWeight)  // 4.0

// Export to SVG
let vGraph = LayoutBridge.layoutSugiyama(graph: g, title: "My Graph", highlightEdges: Set(mst.edges))
let svg = SVGGraphRenderer.renderToSVG(vGraph)
try svg.write(toFile: "graph.svg", atomically: true, encoding: .utf8)
```

---

## Combinatorial Optimization Suite

### 1. Random Graph Generation

> **Reference:** [`docs/Generators.md`](docs/Generators.md)

| # | Model | Generator |
|---|---|---|
| 1.1 | Fisher-Yates Random Permutation | `RandomPermutation.generate(n:)` |
| 1.2 | Erdős-Rényi $G(n, m)$ and $G(n, p)$ | `RandomGraph.build(vertex:edge:)` |
| 1.3 | Bipartite Random Graph | `BipartiteRandomGraph.build(partition:partition:edge:)` |
| 1.4 | $d$-Regular Graph (Pairing Model) | `RandomRegularGraph.build(vertex:degree:)` |
| 1.5 | Spanning Tree (Wilson's LERW) | `RandomTree.spanningTree(from:)` |
| 1.6 | Labeled Tree (Prüfer Sequence) | `RandomTree.labeledTree(vertex:)` |
| 1.7 | Rooted Unlabeled Tree | `RandomTree.unlabeledRootedTree(vertex:)` |
| 1.8 | Connected Random Graph | `RandomConnectedGraph.build(vertex:edge:)` |
| 1.9 | Hamiltonian Random Graph | `RandomConnectedGraph.hamiltonGraph(vertex:edge:)` |
| 1.10 | Layered Flow Network | `RandomFlowNetwork.build(vertex:layerCount:)` |
| 1.11 | Isomorphic Graph Pair | `RandomIsomorphicGraph.build(vertex:edge:)` |
| 1.12 | Isomorphic Regular Graph Pair | `RandomIsomorphicGraph.buildRegular(vertex:degree:)` |

```swift
// G(n, m): 10 vertices, 15 edges
let g = try RandomGraph.build(vertex: 10, edge: 15)

// Isomorphic pair with bijection π
let pair = try RandomIsomorphicGraph.build(vertex: 8, edge: 12)
// pair.original, pair.permuted, pair.permutation
```

---

### 2. Connectivity

> **Reference:** [`docs/Algorithms.md#2-connectivity`](docs/Algorithms.md#2-connectivity)  
> **Source:** [`Connectivity.swift`](Sources/NetworkGraph/Algorithms/Connectivity.swift)

| # | Algorithm | Method |
|---|---|---|
| 2.1 | Harary $k$-connected graph $H_{k,n}$ | `Connectivity.hararyGraph(connectivity:vertexCount:)` |
| 2.2 | Full DFS with edge classification | `Connectivity.dfs(graph:start:)` |
| 2.3 | Layered BFS with distances | `Connectivity.bfs(graph:start:)` |
| 2.4 | Connectivity testing | `Connectivity.isConnected(graph:)` |
| 2.5 | Connected components | `Connectivity.connectedComponents(graph:)` |
| 2.6 | Hopcroft-Tarjan Articulation Points & Bridges $O(V+E)$ | `Connectivity.findCutNodesAndBridges(in:)` |
| 2.7 | Tarjan SCC + Condensation DAG | `Connectivity.stronglyConnectedComponents(in:)` |
| 2.8 | Minimal Equivalent Graph (Transitive Reduction) | `Connectivity.minimalEquivalentGraph(in:)` |
| 2.9 | Stoer-Wagner Global Min-Cut | `Connectivity.globalMinimumCut(graph:)` |
| 2.10 | Kruskal MST $O(E \log E)$ | `Connectivity.minimumSpanningTree(graph:)` |
| 2.11 | Bron-Kerbosch Maximal Cliques | `Connectivity.allCliques(in:)` |

```swift
let mst = Connectivity.minimumSpanningTree(graph: weightedGraph)
print("MST weight: \(mst.totalWeight)")

let (cuts, bridges) = Connectivity.findCutNodesAndBridges(in: g)
let scc = Connectivity.stronglyConnectedComponents(in: digraph)
```

---

### 3. Paths and Cycles

> **Reference:** [`docs/Algorithms.md#3-paths-and-cycles`](docs/Algorithms.md#3-paths-and-cycles)  
> **Source:** [`PathsAndCycles.swift`](Sources/NetworkGraph/Algorithms/PathsAndCycles.swift)

| # | Algorithm | Method |
|---|---|---|
| 3.1 | Fundamental Cycle Basis | `PathsAndCycles.fundamentalCycleBasis(in:)` |
| 3.2 | Girth (shortest cycle length) | `PathsAndCycles.girth(of:)` |
| 3.3 | Bidirectional Dijkstra | `PathsAndCycles.bidirectionalDijkstra(graph:source:target:)` |
| 3.4 | Bellman-Ford SSSP + negative cycle detection | `PathsAndCycles.bellmanFord(graph:source:)` |
| 3.5 | Shortest Path Tree | `PathsAndCycles.shortestPathTree(graph:source:)` |
| 3.6 | Floyd-Warshall APSP $O(V^3)$ | `PathsAndCycles.floydWarshall(graph:)` |
| 3.7 | Yen's $k$-shortest loopless paths | `PathsAndCycles.kShortestPaths(graph:source:target:k:)` |
| 3.8 | Yen's $k$-shortest paths with loops | `PathsAndCycles.kShortestPathsWithLoops(graph:source:target:k:)` |
| 3.9 | Hierholzer Euler Circuit & Trail | `PathsAndCycles.eulerCircuit(in:)` |
| 3.10 | Held-Karp Hamiltonian Cycle DP | `PathsAndCycles.hamiltonianCycle(in:)` |
| 3.11 | Chinese Postman Tour | `PathsAndCycles.chinesePostmanTour(graph:)` |
| 3.12 | Traveling Salesman (Exact DP + 2-opt) | `PathsAndCycles.travelingSalesman(graph:)` |

```swift
let apsp = PathsAndCycles.floydWarshall(graph: g)
let path = apsp.shortestPath(from: 0, to: 7)

let tsp = PathsAndCycles.travelingSalesman(graph: completeGraph)
print("Tour: \(tsp.tour), cost: \(tsp.totalCost)")
```

---

### 4. Planarity Testing

> **Source:** [`Planarity.swift`](Sources/NetworkGraph/Algorithms/Planarity.swift)

Hopcroft-Tarjan linear-time $O(V+E)$ planarity test based on DFS cycle interlacement:

```swift
let result = Planarity.isPlanar(graph)
print(result.isPlanar ? "Planar ✅" : "Non-planar ❌")
```

**Theorem (Kuratowski):** A graph is planar if and only if it contains no subdivision of $K_5$ or $K_{3,3}$.

---

### 5. Graph Isomorphism

> **Source:** [`Isomorphism.swift`](Sources/NetworkGraph/Algorithms/Isomorphism.swift)

Three-tier approach combining rapid pre-filtering with exact search:

1. **Degree sequence check** — $O(V \log V)$
2. **1-WL Color Refinement** (Weisfeiler-Leman) — $O(V \cdot E)$ structural fingerprint
3. **VF2 State-Space Search** — exact bijection $\pi: V(G_1) \to V(G_2)$

```swift
let result = GraphIsomorphism.areIsomorphic(g1, g2)
if result.isIsomorphic { print("Mapping π:", result.mapping!) }

// Fast O(V) AHU canonical string for trees
let same = GraphIsomorphism.areTreesIsomorphic(tree1, tree2)
```

---

### 6. Coloring

> **Source:** [`Coloring.swift`](Sources/NetworkGraph/Algorithms/Coloring.swift)

```swift
// 6.1 DSatur vertex coloring — finds χ(G) and color classes
let col = GraphColoring.color(graph)
print("χ(G) =", col.chromaticNumber)
print("Classes:", col.colorClasses)

// 6.2 Chromatic polynomial P(G, k) via Deletion-Contraction
let poly = GraphColoring.chromaticPolynomial(graph)
let ways = GraphColoring.evaluateChromaticPolynomial(poly, at: 4)
// Number of proper 4-colorings of graph
```

---

### 7. Graph Matching

> **Source:** [`Matching.swift`](Sources/NetworkGraph/Algorithms/Matching.swift)

```swift
// 7.1 Hopcroft-Karp bipartite matching O(E√V)
let bip = GraphMatching.hopcroftKarp(graph: g, partitionV1: [0, 1, 2])

// 7.1 Edmonds' Blossom for general graphs O(V²E)
let gen = GraphMatching.edmondsBlossom(graph)

// 7.2 Hungarian min-sum perfect matching O(V³)
let (assign, cost) = GraphMatching.hungarianAssignment(costMatrix: matrix)
```

---

### 8. Network Flow

> **Source:** [`DinicPushRelabelFlow.swift`](Sources/NetworkGraph/Algorithms/DinicPushRelabelFlow.swift)

```swift
// 8.1 Dinic's blocking flow O(V²E)
let (maxF, net) = AdvancedFlow.dinicMaxFlow(in: network, from: s, to: t)

// 8.1 Push-Relabel highest-label O(V³)
let (flow, _) = AdvancedFlow.pushRelabelMaxFlow(in: network, from: s, to: t)

// 8.2 Min-Cost Max-Flow (Successive Shortest Path)
let res = AdvancedFlow.minCostMaxFlow(in: network, from: s, to: t)
print("Flow: \(res.maxFlow), Cost: \(res.totalCost)")
```

---

### 9. Packing and Covering

> **Source:** [`PackingAndCovering.swift`](Sources/NetworkGraph/Algorithms/PackingAndCovering.swift)

```swift
// 9.1 Linear Sum Assignment O(V³)
let (assign, cost) = PackingAndCovering.linearAssignment(costMatrix: C)

// 9.2 Bottleneck Assignment (min max c_ij)
let (assign, bottle) = PackingAndCovering.bottleneckAssignment(costMatrix: C)

// 9.3 Quadratic Assignment Problem (exact for n≤8, 2-opt heuristic otherwise)
let qap = PackingAndCovering.quadraticAssignment(flowMatrix: F, distanceMatrix: D)

// 9.4 Multiple Knapsack Problem (branch-and-bound)
let mkp = PackingAndCovering.multipleKnapsack(profits: p, weights: w, capacities: caps)

// 9.5 Set Covering (exact B&B or greedy ln|U| approximation)
let sc = PackingAndCovering.setCover(universeSize: 8, subsets: subsetList)

// 9.6 Set Partitioning / Exact Cover
let sp = PackingAndCovering.setPartitioning(universeSize: 6, subsets: partList)
```

---

## Foundational ADTs

### `DisjointSet` (Union-Find)

Path compression + union-by-rank; amortized inverse-Ackermann $\alpha(n)$ per operation:

```swift
var ds = DisjointSet(count: 10)
ds.union(0, 3)
ds.union(3, 7)
print(ds.connected(0, 7))   // true
print(ds.componentCount)     // 8
print(ds.size(of: 0))        // 3
```

### `BitVector`

64-bit word-aligned bitset; all set operations in $O(N/64)$:

```swift
var bv = BitVector(size: 128, bitPattern: [0, 42, 63, 64, 127])
print(bv.count)                    // 5
print(bv.contains(42))             // true
let u = bv.union(other)            // bitwise OR
let i = bv.intersection(other)     // bitwise AND
let d = bv.difference(other)       // bitwise AND-NOT
print(bv.intersects(other))        // fast non-empty intersection test
```

---

## Visualization & Layout Bridge

> **Reference:** [`docs/Visualization.md`](docs/Visualization.md)

```swift
import NetworkGraph

// 1. Run any optimization algorithm and collect annotation sets
let mst = Connectivity.minimumSpanningTree(graph: weightedGraph)
var labels: [Edge: String] = [:]
for e in weightedGraph.edges {
    if let w = weightedGraph.edgeProperties[e] { labels[e] = "\(Int(w))" }
}

// 2. Lay out the graph (Sugiyama hierarchical or circular)
let vGraph = LayoutBridge.layoutSugiyama(
    graph: weightedGraph,
    title: "Minimum Spanning Tree (weight \(mst.totalWeight))",
    highlightEdges: Set(mst.edges),
    edgeLabels: labels,
    theme: .modernDark
)

// 3. Render to SVG
let svg = SVGGraphRenderer.renderToSVG(vGraph)
try svg.write(toFile: "mst.svg", atomically: true, encoding: .utf8)
```

**Layout modes:**

| Layout | Best for |
|---|---|
| `layoutSugiyama` | DAGs, flow networks, dependency graphs, MSTs |
| `layoutCircular` | Hamiltonian tours, TSP, regular graphs, social networks |

**SVG features:** Dark/light themes, glowing neon highlights, directional arrow markers, floating edge weight labels, responsive viewport.

---

## CLI (`net`)

> **Reference:** [`docs/CLI.md`](docs/CLI.md)

```bash
# Solve and visualize — all in one command
swift run net random  --type flow --vertices 8 --output flow_net.svg
swift run net mst     --vertices 10 --edges 20  --output mst.svg
swift run net tsp     --cities 7                --output tsp.svg
swift run net flow    --vertices 8              --output flow.svg
swift run net color   --vertices 10 --edges 18  --output coloring.svg
swift run net match   --size 5                  --output matching.svg
swift run net planar  --vertices 5 --edges 10

# Open result immediately in browser
swift run net mst --vertices 12 --output mst.svg && open mst.svg
```

---

## Core Architecture

> **Reference:** [`docs/CoreArchitecture.md`](docs/CoreArchitecture.md)

### Graph Protocols

| Protocol | Adds |
|---|---|
| `Graph` | `.kind`: `.directed` / `.undirected` |
| `VertexListGraph` | `vertexCount`, `vertices`, `index(of:)` |
| `EdgeListGraph` | `edgeCount`, `edges` |
| `IncidenceGraph` | `degree`, `adjacent(of:)`, `isAdjacent`, `adjacentEdges` |
| `BidirectionalGraph` | `indegree`, `inEdges(vertex:)` |
| `MutableGraph` | `addVertex`, `removeVertex`, `addEdge`, `removeEdge` |
| `PropertyGraph` | Vertex and edge subscript read/write |
| `NetworkFlowGraph` | Flow attribute API, `source`/`sink` |

### Vertex Types

| Type | Use case |
|---|---|
| `Int`, `String`, … | Simple scalar identity |
| `LabeledVertex` | Named nodes (symbol graphs) |
| `AnnotatedVertex` | Exploratory graphs with freeform metadata |
| `FlowVertex` | Flow networks: `excess`, `height`, `supply` |
| Custom struct | Domain-specific models |

### Edge Types

| Type | Use case |
|---|---|
| `NoProperty` | Topology-only (unweighted) graphs |
| `Double`, `Int`, … | Simple scalar weights |
| `WeightedEdge` | Named weighted edges |
| `AnnotatedEdge` | Freeform metadata arcs |
| `FlowEdge` | Flow networks: `capacity`, `flow`, `cost`, `lowerBound` |

### Graph Construction

```swift
// Empty
var g = AdjacentGraph<Int, NoProperty>()
var g = AdjacentGraph<Int, NoProperty>(kind: .undirected)

// From vertex list
var g = AdjacentGraph<String, NoProperty>(vertices: ["A", "B", "C"])

// From vertices + edge pairs
var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<5),
                                       edges: [(0,1), (1,2), (2,3)])

// From CSV-style weighted triples
var g = AdjacentGraph<String, Double>([("A","B","1.5"), ("B","C","2.3")])

// From adjacency list
var g = AdjacentGraph<Int, NoProperty>(vertices: [0,1,2], adacency: [[1,2],[2],[]])
```

### Property Access

```swift
// Vertex
let v: String = g[0]
g[0] = "Updated"

// Edge (force unwrap)
let w: Double = g[Edge(u: 0, v: 1)]
g[Edge(u: 0, v: 1)] = 3.5

// Edge (safe optional)
let w: Double? = g[safe: Edge(u: 0, v: 1)]
g[safe: Edge(u: 0, v: 1)] = 3.5
```

---

## Classic Network Flow (Ford-Fulkerson)

```swift
var net = FlowNetwork(vertices: [
    FlowVertex(label: "S"), FlowVertex(label: "A"),
    FlowVertex(label: "B"), FlowVertex(label: "T")
], kind: .directed)

_ = net.addEdge(u: 0, v: 1); net[Edge(u:0,v:1)] = FlowEdge(capacity: 10)
_ = net.addEdge(u: 0, v: 2); net[Edge(u:0,v:2)] = FlowEdge(capacity: 5)
_ = net.addEdge(u: 1, v: 3); net[Edge(u:1,v:3)] = FlowEdge(capacity: 10)
_ = net.addEdge(u: 2, v: 3); net[Edge(u:2,v:3)] = FlowEdge(capacity: 5)

// Classic Ford-Fulkerson (original API)
let (maxFlowValue, resultNet) = maxFlow(in: net, from: 0, to: 3)
print("Max flow: \(maxFlowValue)")

// Advanced: Dinic O(V²E)
let (dinicFlow, _) = AdvancedFlow.dinicMaxFlow(in: net, from: 0, to: 3)
```

---

## File Import

### Text format (Sedgewick-style)

```
13    ← vertex count
15    ← edge count
0 5   ← edge pairs, one per line
...
```

```swift
var g = AdjacentGraph<Int, NoProperty>()
let data = try readBundle(file: "tinyDG", ofType: "txt", separator: " ")
g.initialize(unweightedGraph: data)
```

### Weighted text format

```swift
var g = AdjacentGraph<Int, Double>()
let data = try readBundle(file: "tinyEWD", ofType: "txt", separator: " ")
g.initializeGraph(weightedGraph: data)
```

### CSV / symbol graph

```swift
let data = try readBundle(file: "usa-map", ofType: "csv", separator: ",").map { $0.splat3() }
let g = AdjacentGraph<String, Int>(data)
```

---

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hakkabon/NetworkGraph.git", branch: "main"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "NetworkGraph", package: "NetworkGraph"),
    ]),
]
```

---

## Testing

Run the full test suite (130 tests, 0 failures):

```bash
swift test
```

| Test Suite | Topics Covered | Tests |
|---|---|---|
| `ADTTests` | DisjointSet, BitVector | 5 |
| `RandomGeneratorsTests` | 1.1 – 1.12 | 12 |
| `ConnectivityAlgorithmsTests` | 2.1 – 2.11 | 11 |
| `PathsAndCyclesTests` | 3.1 – 3.12 | 10 |
| `PlanarityIsomorphismColoringMatchingTests` | 4.1, 5.1, 6.1–6.2, 7.1–7.2 | 8 |
| `AdvancedFlowAndPackingCoveringTests` | 8.1–8.2, 9.1–9.6 | 8 |
| `VisualizationTests` | Sugiyama layout, Circular layout, SVG | 2 |
| Existing regression suites | Graph structure, flow, traversal | 74 |

---

## Documentation

| Document | Contents |
|---|---|
| [`docs/Algorithms.md`](docs/Algorithms.md) | Full API reference for Topics 2–9 |
| [`docs/Generators.md`](docs/Generators.md) | Random graph generator reference (Topics 1.1–1.12) |
| [`docs/CoreArchitecture.md`](docs/CoreArchitecture.md) | Protocol hierarchy, vertex/edge types, graph construction, property access |
| [`docs/Visualization.md`](docs/Visualization.md) | LayoutBridge, SVGGraphRenderer, GraphVisualTheme, workflow examples |
| [`docs/CLI.md`](docs/CLI.md) | `net` CLI subcommand reference with examples |

---

## License

MIT License — see [LICENSE](LICENSE) for details.
