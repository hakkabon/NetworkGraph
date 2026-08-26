# Random Graph Generators Reference

## Overview

The `Generators` module provides factory enums for producing provably-structured random graphs. All generators throw `GraphError` on impossible parameter combinations (e.g. requesting more edges than possible in a bipartite graph with given partition sizes).

**Source directory:** [`Sources/NetworkGraph/Generators/`](Sources/NetworkGraph/Generators/)

---

## 1.1 Random Permutation

**Source:** [`RandomPermutation.swift`](Sources/NetworkGraph/Generators/RandomPermutation.swift)

Generates a uniform random permutation of $n$ integers using the Fisher-Yates (Knuth) shuffle.

```swift
let π = RandomPermutation.generate(n: 10)
// π is a uniformly random permutation of [0, 1, ..., 9]
```

**Complexity:** $O(n)$ time and space.

---

## 1.2 Random Graph — Erdős-Rényi Models

**Source:** [`RandomGraph.swift`](Sources/NetworkGraph/Generators/RandomGraph.swift)

Two standard models:

| Function | Model | Parameter | Description |
|---|---|---|---|
| `RandomGraph.build(vertex:edge:)` | $G(n, m)$ | $m$ exact edges | Uniform over all graphs with exactly $m$ edges |
| `RandomGraph.build(vertex:probability:)` | $G(n, p)$ | $p$ edge prob. | Each pair $(i,j)$ is independently connected with probability $p$ |

```swift
// G(10, 15): exactly 15 edges among 10 vertices
let gm = try RandomGraph.build(vertex: 10, edge: 15)

// G(10, 0.3): each of 45 possible edges present w.p. 0.3
let gp = try RandomGraph.build(vertex: 10, probability: 0.3)
```

**Expected edges in $G(n, p)$:** $\binom{n}{2} p$

---

## 1.3 Bipartite Random Graph

**Source:** [`RandomGraph.swift`](Sources/NetworkGraph/Generators/RandomGraph.swift)

Bipartite graph with fixed partition sizes:

```swift
// 5+5 bipartite, 8 edges
let bip = try BipartiteRandomGraph.build(partition: 5, partition: 5, edge: 8)
```

The graph is undirected; vertices $0 \ldots n_1-1$ form $V_1$ and $n_1 \ldots n_1+n_2-1$ form $V_2$. Only edges crossing the partition are added.

---

## 1.4 Random Regular Graph

**Source:** [`RandomRegularGraph.swift`](Sources/NetworkGraph/Generators/RandomRegularGraph.swift)

Produces a uniformly-random $d$-regular graph on $n$ vertices (every vertex has degree exactly $d$). Uses the **pairing configuration model**: creates $nd$ half-edges, pairs them uniformly at random, and rejects multi-edges and self-loops via repeated restarts.

```swift
let reg = try RandomRegularGraph.build(vertex: 10, degree: 3)
// All 10 vertices have degree 3
```

**Requirements:** $nd$ must be even.

**Complexity:** Expected $O(n d^2)$ with high probability of success for fixed $d$.

---

## 1.5 Random Spanning Tree

**Source:** [`RandomTree.swift`](Sources/NetworkGraph/Generators/RandomTree.swift)

Returns a uniformly random spanning tree of the complete graph $K_n$ using **Wilson's Loop-Erased Random Walk** algorithm.

```swift
let tree = try RandomTree.spanningTree(from: baseGraph)
// Undirected tree, exactly n-1 edges
```

**Complexity:** Expected $O(n^2)$ for complete graphs; faster on sparse base graphs.

---

## 1.6 Random Labeled Tree (Prüfer Sequence)

**Source:** [`RandomTree.swift`](Sources/NetworkGraph/Generators/RandomTree.swift)

Generates a uniformly random labeled tree on $n$ vertices by sampling a random Prüfer sequence of length $n-2$ and decoding it to an edge set (Cayley's formula gives $n^{n-2}$ such trees).

```swift
let labeled = try RandomTree.labeledTree(vertex: 6)
// One of 6^4 = 1296 possible labeled trees on 6 vertices
```

**Complexity:** $O(n)$.

---

## 1.7 Random Unlabeled Rooted Tree

**Source:** [`RandomTree.swift`](Sources/NetworkGraph/Generators/RandomTree.swift)

Samples a uniformly random unlabeled rooted tree structure on $n$ vertices using the **Remy–Robinson partition distribution** (recursive subtree-size sampling).

```swift
let rooted = try RandomTree.unlabeledRootedTree(vertex: 7)
```

---

## 1.8 Random Connected Graph

**Source:** [`RandomConnectedGraph.swift`](Sources/NetworkGraph/Generators/RandomConnectedGraph.swift)

Guarantees connectivity by first generating a spanning tree (Wilson's algorithm), then adding $m - (n-1)$ additional random edges from the pool of non-tree edges.

```swift
let g = try RandomConnectedGraph.build(vertex: 8, edge: 14)
// Always connected; exactly 14 edges
```

**Throws:** if $m < n-1$ (insufficient edges for connectivity).

---

## 1.9 Random Hamiltonian Graph

**Source:** [`RandomConnectedGraph.swift`](Sources/NetworkGraph/Generators/RandomConnectedGraph.swift)

Generates a random graph guaranteed to contain at least one Hamiltonian cycle by:
1. Constructing a random $n$-cycle $v_0 \to v_1 \to \ldots \to v_{n-1} \to v_0$ as the backbone.
2. Adding random chords until the target edge count $m$ is reached.

```swift
let ham = try RandomConnectedGraph.hamiltonGraph(vertex: 8, edge: 12)
```

---

## 1.10 Random Maximum Flow Network

**Source:** [`RandomFlowNetwork.swift`](Sources/NetworkGraph/Generators/RandomFlowNetwork.swift)

Generates a layered DAG with:
- Vertex 0 as source ($s$) and vertex $n-1$ as sink ($t$)
- Guaranteed $s \to t$ path through every layer
- Random capacities in a configurable range
- Optional per-arc costs for min-cost flow benchmarks

```swift
let net = try RandomFlowNetwork.build(vertex: 8, layerCount: 3)
let net2 = try RandomFlowNetwork.build(vertex: 10, layerCount: 4, capacityRange: 5...20, costRange: 1...5)
```

---

## 1.11 Random Isomorphic Graphs (General)

**Source:** [`RandomIsomorphicGraph.swift`](Sources/NetworkGraph/Generators/RandomIsomorphicGraph.swift)

Returns a pair `(original, permuted, π)` where `permuted` is obtained by relabeling `original`'s vertices via a random permutation $\pi$.

```swift
let pair = try RandomIsomorphicGraph.build(vertex: 8, edge: 12)
// pair.original, pair.permuted — structurally identical
// pair.permutation[i] — vertex i in original maps to pair.permutation[i] in permuted
```

---

## 1.12 Random Isomorphic Regular Graphs

**Source:** [`RandomIsomorphicGraph.swift`](Sources/NetworkGraph/Generators/RandomIsomorphicGraph.swift)

As above, but starting from a uniform random $d$-regular graph:

```swift
let pair = try RandomIsomorphicGraph.buildRegular(vertex: 10, degree: 3)
```

---

## Named Graph Topologies

**Source:** [`NamedGraph.swift`](Sources/NetworkGraph/Generators/NamedGraph.swift)

Classic deterministic topologies:

```swift
// Complete graph K_n: every pair connected
let k5 = CompleteGraph<Int>.build(vertices: Array(0..<5))

// Star graph: one hub connected to n leaves
let star = StarGraph<Int>.build(withCenter: 0, andLeafs: Array(1...6))

// Path graph: 0—1—2—3—4
let path = PathGraph<Int>.withPath(Array(0..<5))

// Cycle graph: 0—1—2—3—0
let cycle = CycleGraph<Int>.withCycle(Array(0..<4))
```
