# Algorithms Reference

## Overview

The `NetworkGraph` combinatorial optimization engine is organized into eight algorithm modules, two foundational ADTs, and a vector visualization suite. All modules are pure value-type Swift — no reference semantics, no hidden side-effects. Every algorithm works against the generic `AdjacentGraph<V, W>` container.

---

## Module Map

| File | Topic(s) | Key Complexity |
|---|---|---|
| [`Connectivity.swift`](Sources/NetworkGraph/Algorithms/Connectivity.swift) | Topics 2.1–2.11 | $O(V+E)$ to $O(V^3)$ |
| [`PathsAndCycles.swift`](Sources/NetworkGraph/Algorithms/PathsAndCycles.swift) | Topics 3.1–3.12 | $O(E \log V)$ to $O(n^2 2^n)$ |
| [`Planarity.swift`](Sources/NetworkGraph/Algorithms/Planarity.swift) | Topic 4.1 | $O(V+E)$ |
| [`Isomorphism.swift`](Sources/NetworkGraph/Algorithms/Isomorphism.swift) | Topic 5.1 | $O(V!)$ worst-case (VF2 + 1-WL pruning) |
| [`Coloring.swift`](Sources/NetworkGraph/Algorithms/Coloring.swift) | Topics 6.1–6.2 | $O(V^2)$ / $O(2^V \cdot V)$ |
| [`Matching.swift`](Sources/NetworkGraph/Algorithms/Matching.swift) | Topics 7.1–7.2 | $O(E \sqrt{V})$ / $O(V^3)$ |
| [`DinicPushRelabelFlow.swift`](Sources/NetworkGraph/Algorithms/DinicPushRelabelFlow.swift) | Topics 8.1–8.2 | $O(V^2 E)$ / $O(V^3)$ |
| [`PackingAndCovering.swift`](Sources/NetworkGraph/Algorithms/PackingAndCovering.swift) | Topics 9.1–9.6 | $O(V^3)$ to NP |

---

## 2. Connectivity

**Source:** [`Connectivity.swift`](Sources/NetworkGraph/Algorithms/Connectivity.swift)

### 2.1 Harary Graphs

Constructs Harary graphs $H_{k,n}$ — $k$-edge-connected regular graphs with the minimum number of edges $\lceil kn/2 \rceil$.

```swift
let h = Connectivity.hararyGraph(connectivity: 3, vertexCount: 10)
```

### 2.2 Depth-First Search

Full DFS with complete event classification: discovers tree edges, back edges, forward edges, and cross edges; records discovery and finish timestamps.

```swift
let dfsResult = Connectivity.dfs(graph: g, start: 0)
// dfsResult.treeEdges, .backEdges, .forwardEdges, .crossEdges
// dfsResult.discoveryTime[v], dfsResult.finishTime[v]
```

### 2.3 Breadth-First Search

Layered BFS computing exact shortest-hop distances and predecessor mapping.

```swift
let bfsResult = Connectivity.bfs(graph: g, start: 0)
// bfsResult.layers[d] = [vertices at depth d]
// bfsResult.dist[v], bfsResult.predecessor[v]
```

### 2.4 Connectivity Testing

```swift
let isConnected = Connectivity.isConnected(graph: g)
let isStronglyConnected = Connectivity.isStronglyConnected(graph: g)
```

### 2.5 Connected Components

```swift
let components = Connectivity.connectedComponents(graph: g)
// components[i] = [vertex indices in component i]
```

### 2.6 Articulation Points & Bridges

Hopcroft-Tarjan single-pass $O(V+E)$ algorithm:

```swift
let (cutNodes, bridges) = Connectivity.findCutNodesAndBridges(in: g)
```

### 2.7 Strongly Connected Components (Tarjan)

```swift
let sccResult = Connectivity.stronglyConnectedComponents(in: g)
let condensation = sccResult.condensationGraph  // DAG of SCCs
```

### 2.8 Minimal Equivalent Graph (Transitive Reduction)

Returns the minimum-edge subgraph with identical transitive reachability:

```swift
let meg = Connectivity.minimalEquivalentGraph(in: dag)
```

### 2.9 Global Minimum Cut (Stoer-Wagner)

```swift
let minCut = Connectivity.globalMinimumCut(graph: weightedGraph)
// minCut.value, minCut.partition1, minCut.partition2
```

### 2.10 Minimum Spanning Tree (Kruskal)

```swift
let mst = Connectivity.minimumSpanningTree(graph: weightedGraph)
// mst.edges, mst.totalWeight, mst.treeGraph
```

### 2.11 Maximal & Maximum Cliques (Bron-Kerbosch)

```swift
let maximalCliques = Connectivity.allCliques(in: g)
let maxClique = Connectivity.maximumClique(in: g)  // ω(G)
```

---

## 3. Paths and Cycles

**Source:** [`PathsAndCycles.swift`](Sources/NetworkGraph/Algorithms/PathsAndCycles.swift)

### 3.1 Fundamental Cycle Basis

Computes a minimum set of independent cycles forming a basis for the cycle space $\mathcal{C}(G)$. Uses spanning-tree chord analysis.

```swift
let basis = PathsAndCycles.fundamentalCycleBasis(in: g)
// basis.cycles — each cycle as an ordered array of vertex indices
// basis.cyclomaticNumber — |E| - |V| + |components|
```

### 3.2 Girth

Shortest cycle length (girth) via per-vertex BFS:

```swift
let g_len = PathsAndCycles.girth(of: g)  // nil if no cycle exists (tree)
```

### 3.3 Bidirectional Dijkstra

Meet-in-the-middle shortest path for better performance on large sparse graphs:

```swift
let sp = PathsAndCycles.bidirectionalDijkstra(graph: g, source: 0, target: n-1)
// sp.distance, sp.path
```

### 3.4 Bellman-Ford (SSSP with Negative Weights)

```swift
let (dist, pred, hasNegCycle) = PathsAndCycles.bellmanFord(graph: g, source: 0)
if hasNegCycle { print("Negative cycle detected") }
```

### 3.5 Shortest Path Tree

```swift
let spt = PathsAndCycles.shortestPathTree(graph: g, source: 0)
// spt — AdjacentGraph<Int, W> rooted shortest path tree
```

### 3.6 Floyd-Warshall (APSP)

```swift
let apsp = PathsAndCycles.floydWarshall(graph: g)
let d = apsp.distance(from: i, to: j)
let path = apsp.shortestPath(from: i, to: j)  // reconstructed vertex sequence
```

### 3.7 & 3.8 Yen's k-Shortest Paths

```swift
// Without repeated vertices (loopless)
let loopless = PathsAndCycles.kShortestPaths(graph: g, source: 0, target: t, k: 5)

// With repeated vertices
let withLoops = PathsAndCycles.kShortestPathsWithLoops(graph: g, source: 0, target: t, k: 5)
```

### 3.9 Euler Circuit & Trail (Hierholzer)

```swift
// Euler circuit (returns nil if graph doesn't have one)
let circuit = PathsAndCycles.eulerCircuit(in: g)

// Euler trail (from odd-degree vertex to odd-degree vertex)
let trail = PathsAndCycles.eulerTrail(in: g)
```

### 3.10 Hamiltonian Cycle (Held-Karp)

Exact DP ($O(n^2 2^n)$) for small $n \leq 20$, backtracking for larger:

```swift
let result = PathsAndCycles.hamiltonianCycle(in: g)
// result.cycle, result.exists
```

### 3.11 Chinese Postman Tour

For undirected graphs: matches odd-degree vertices with minimum-weight perfect matching, then adds duplicate edges and finds Euler circuit.

```swift
let tour = PathsAndCycles.chinesePostmanTour(graph: weightedGraph)
// tour.circuit, tour.totalWeight, tour.extraEdges
```

### 3.12 Traveling Salesman Problem (TSP)

```swift
// Exact Held-Karp DP O(n^2 2^n), optimal for small n
// 2-opt local search heuristic for larger n
let tsp = PathsAndCycles.travelingSalesman(graph: completeGraph)
// tsp.tour, tsp.totalCost, tsp.isOptimal
```

---

## 4. Planarity Testing

**Source:** [`Planarity.swift`](Sources/NetworkGraph/Algorithms/Planarity.swift)

Based on Hopcroft-Tarjan's linear-time algorithm:

1. Checks Euler's formula: $|E| \leq 3|V| - 6$ (3|V|-4 for bipartite).
2. Constructs a DFS tree and classifies back edges as interlacing segments.
3. Tests if the interlacement graph of cycle segments is bipartite (two-colorable).

```swift
let result = Planarity.isPlanar(graph)
// result.isPlanar (Bool)
// result.faces    (Int) — Euler formula: V - E + F = 2
```

> **Theorem (Kuratowski):** A graph is planar iff it contains no subdivision of $K_5$ or $K_{3,3}$.

---

## 5. Graph Isomorphism Testing

**Source:** [`Isomorphism.swift`](Sources/NetworkGraph/Algorithms/Isomorphism.swift)

Three-phase approach for general graphs, one-phase for trees:

### General Graphs

1. **Quick checks**: Vertex count, edge count, degree sequence.
2. **1-WL Color Refinement** (Weisfeiler-Leman): Iteratively relabels vertices by their neighborhood multiset signature. Distinguishes most non-isomorphic pairs in $O(V \cdot E)$.
3. **VF2 State-Space Search**: Exact backtracking with consistency checks against the current partial mapping. Returns the bijective mapping $\pi: V(G_1) \to V(G_2)$ on success.

```swift
let result = GraphIsomorphism.areIsomorphic(g1, g2)
// result.isIsomorphic, result.mapping (optional)
```

### Tree Isomorphism (AHU Algorithm)

Linear-time $O(V)$ canonical string encoding via centroid decomposition:

```swift
let same = GraphIsomorphism.areTreesIsomorphic(tree1, tree2)
```

---

## 6. Coloring

**Source:** [`Coloring.swift`](Sources/NetworkGraph/Algorithms/Coloring.swift)

### 6.1 Node Coloring (DSatur)

**DSatur** (Degree of Saturation) orders vertices by the number of distinct colors among their neighbors, breaking ties by total degree. Produces near-optimal proper colorings:

```swift
let result = GraphColoring.color(graph)
// result.chromaticNumber  — χ(G)
// result.colors           — [vertexIndex: colorIndex]
// result.colorClasses     — [[Int]] — partition of vertices by color
```

**Properties guaranteed:**
- `colors[u] != colors[v]` for all edges $(u, v)$
- `chromaticNumber` is a valid upper bound on $\chi(G)$

### 6.2 Chromatic Polynomial

Exact computation via the Deletion-Contraction recursion:
$$P(G, k) = P(G - e, k) - P(G / e, k)$$

Returns polynomial coefficients $[a_0, a_1, \ldots, a_n]$ where $P(G, k) = \sum_i a_i k^i$:

```swift
let poly = GraphColoring.chromaticPolynomial(tree3)
// Evaluates P(T_3, k) = k(k-1)^2 = k^3 - 2k^2 + k
let ways = GraphColoring.evaluateChromaticPolynomial(poly, at: 3)  // 12.0
```

---

## 7. Graph Matching

**Source:** [`Matching.swift`](Sources/NetworkGraph/Algorithms/Matching.swift)

### 7.1 Hopcroft-Karp (Bipartite)

Layered BFS to find blocking flows in the bipartite matching auxiliary graph:

```swift
let result = GraphMatching.hopcroftKarp(graph: g, partitionV1: [0, 1, 2])
// result.cardinality  — |M|
// result.matchedEdges — [(u, v)]
// result.matchOf      — [Int: Int]
```

**Complexity:** $O(E \sqrt{V})$

### 7.1 Edmonds' Blossom (General Graphs)

Handles odd-length cycles (blossoms) through contraction and path augmentation:

```swift
let result = GraphMatching.edmondsBlossom(graph)
```

**Complexity:** $O(V^2 E)$

### 7.2 Hungarian Algorithm (Min-Sum Assignment)

Solves the Linear Assignment Problem on an $n \times n$ cost matrix:

```swift
let (assignment, totalCost) = GraphMatching.hungarianAssignment(costMatrix: matrix)
// assignment[i] = j means worker i is assigned to job j
```

**Complexity:** $O(V^3)$

---

## 8. Advanced Network Flow

**Source:** [`DinicPushRelabelFlow.swift`](Sources/NetworkGraph/Algorithms/DinicPushRelabelFlow.swift)

### 8.1 Dinic's Blocking Flow

Builds a layered residual graph (BFS) and pushes blocking flows through each level via DFS:

```swift
let (maxFlow, solvedNet) = AdvancedFlow.dinicMaxFlow(in: net, from: s, to: t)
```

**Complexity:** $O(V^2 E)$; $O(E \sqrt{V})$ for unit-capacity graphs

### 8.1 Push-Relabel (Highest-Label)

Maintains preflow and pushes excess greedily from highest active vertices; discharges excess back to source when stuck via relabeling:

```swift
let (flow, solvedNet) = AdvancedFlow.pushRelabelMaxFlow(in: net, from: s, to: t)
```

**Complexity:** $O(V^3)$

### 8.2 Minimum Cost Maximum Flow (Successive Shortest Path)

Augments flow along the cheapest available augmenting path (Dijkstra with Johnson's reduced costs / node potentials):

```swift
let result = AdvancedFlow.minCostMaxFlow(in: net, from: s, to: t)
// result.maxFlow, result.totalCost, result.network
```

**Complexity:** $O(V E \log V \cdot \min(V \cdot E, F_{\max}))$

---

## 9. Packing and Covering

**Source:** [`PackingAndCovering.swift`](Sources/NetworkGraph/Algorithms/PackingAndCovering.swift)

### 9.1 Linear Sum Assignment

Calls the Hungarian algorithm. Wrapper for integration with graph-native code:

```swift
let (assignment, cost) = PackingAndCovering.linearAssignment(costMatrix: matrix)
```

### 9.2 Bottleneck Assignment Problem

Minimizes the maximum cost assigned to any single pair:
$$\min_{M \in \text{perfect matchings}} \max_{(i,j) \in M} c_{ij}$$

Uses binary search on sorted cost values + Hopcroft-Karp feasibility checks:

```swift
let (assignment, bottleneck) = PackingAndCovering.bottleneckAssignment(costMatrix: matrix)
```

### 9.3 Quadratic Assignment Problem (QAP)

$$\min_{\pi \in S_n} \sum_{i,j} F_{ij} D_{\pi(i)\pi(j)}$$

- **Exact** (Branch-and-Bound) for $n \leq 8$
- **2-opt local search** heuristic for $n > 8$

```swift
let result = PackingAndCovering.quadraticAssignment(flowMatrix: F, distanceMatrix: D)
// result.assignment, result.totalCost
```

### 9.4 Multiple Knapsack

Packs $n$ items with profits and weights into $m$ bins with capacities:

```swift
let result = PackingAndCovering.multipleKnapsack(profits: p, weights: w, capacities: c)
// result.binAssignments — [[Int]] (items per bin)
// result.totalProfit
```

### 9.5 Set Covering Problem

$$\min \sum_{j \in S} c_j \quad \text{s.t.} \quad \bigcup_{j \in S} A_j = U$$

- **Exact** bitmask branch-and-bound for $|U|, |S| \leq 30$
- **Greedy** Chvátal $\ln |U|$-approximation for larger instances

```swift
let result = PackingAndCovering.setCover(universeSize: 5, subsets: [[0,1],[1,2],[2,3,4]])
// result.selectedSubsets, result.totalCost, result.isComplete
```

### 9.6 Set Partitioning (Exact Cover)

Finds a collection of pairwise disjoint subsets whose union is exactly $U$:

```swift
let result = PackingAndCovering.setPartitioning(universeSize: 4, subsets: [[0,1],[2,3],[0,2]])
// nil if no exact cover exists
```

---

## Foundational ADTs

### DisjointSet (Union-Find)

**Source:** [`ADTs/DisjointSet.swift`](Sources/NetworkGraph/ADTs/DisjointSet.swift)

Path compression + union-by-rank; inverse-Ackermann $\alpha(n)$ amortized per operation:

```swift
var ds = DisjointSet(count: n)
ds.union(a, b)
ds.find(x)           // canonical root of x's component
ds.connected(x, y)   // Bool
ds.componentCount    // current number of components
ds.size(of: x)       // size of x's component
```

### BitVector

**Source:** [`ADTs/BitVector.swift`](Sources/NetworkGraph/ADTs/BitVector.swift)

64-bit word-aligned bitset; all set operations in $O(N/64)$:

```swift
var bv = BitVector(size: 256)
bv.set(42)
bv.clear(42)
bv.contains(42)        // Bool
bv.count               // popcount (Hamming weight)
bv.isEmpty             // Bool
let u = bv1.union(bv2)
let i = bv1.intersection(bv2)
let d = bv1.difference(bv2)
bv1.intersects(bv2)    // Bool — fast non-empty intersection test
```
