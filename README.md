# NetworkGraph

A generic, protocol-driven Swift package for modelling, traversing, and analysing graphs — from simple social networks to weighted flow networks.  

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)  
[![Platforms](https://img.shields.io/badge/platforms-macOS%2010.13%20%7C%20iOS%2012-blue.svg)](https://developer.apple.com/swift/)  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)  

---

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [Graph Protocols](#graph-protocols)
  - [Vertices](#vertices)
  - [Edges](#edges)
  - [Property Maps](#property-maps)
- [Graph Construction](#graph-construction)
- [Structural Mutations](#structural-mutations)
- [Read/Write Vertex & Edge Properties](#readwrite-vertex--edge-properties)
- [Algorithms](#algorithms)
  - [Depth-First Search](#depth-first-search)
  - [Breadth-First Search](#breadth-first-search)
  - [Topological Sort](#topological-sort)
  - [Connectivity Helpers](#connectivity-helpers)
- [Network Flow](#network-flow)
  - [FlowVertex & FlowEdge](#flowvertex--flowedge)
  - [Building a Flow Network](#building-a-flow-network)
  - [Ford-Fulkerson Max-Flow](#ford-fulkerson-max-flow)
- [Graph Generators](#graph-generators)
- [File Import](#file-import)
- [Installation](#installation)
- [License](#license)

---

## Overview

NetworkGraph provides a single concrete graph type — `AdjacentGraph<V, W>` — built on top of a layered protocol hierarchy inspired by the [Boost Graph Library](https://www.boost.org/doc/libs/release/libs/graph/). The design separates *structure* (vertices, edges, adjacency) from *payload* (vertex values, edge weights, flow attributes), giving you flexibility to model anything from routing tables to supply-chain networks.

Key characteristics:

- **Generic vertex and edge types** — use `Int`, `String`, `FlowVertex`, or any custom `Hashable & Codable` type.
- **Protocol-oriented design** — algorithms depend on the narrowest protocol they need, making them reusable and testable in isolation.
- **Full read/write property access** — subscript and named-method API for both vertex values and edge attributes.
- **Network-flow ready** — `FlowVertex`, `FlowEdge`, and the `NetworkFlowGraph` protocol provide first-class support for max-flow and min-cost-flow modelling.
- **Bidirectional adjacency** — incoming-edge lists are maintained automatically, enabling O(1) in-degree queries.

---

## Quick Start

```swift
import NetworkGraph

// 1. Create a directed weighted graph
var g = AdjacentGraph<String, Double>(
    vertices: ["A", "B", "C", "D"]
)

// 2. Add edges
_ = g.addEdge(u: 0, v: 1)   // A → B
_ = g.addEdge(u: 1, v: 2)   // B → C
_ = g.addEdge(u: 2, v: 3)   // C → D
_ = g.addEdge(u: 0, v: 3)   // A → D

// 3. Annotate edges with weights
g[Edge(u: 0, v: 1)] = 1.5
g[Edge(u: 1, v: 2)] = 2.0
g[Edge(u: 2, v: 3)] = 0.5
g[Edge(u: 0, v: 3)] = 5.0

// 4. Update a vertex value in place
g[0] = "Alpha"

// 5. Query the graph
print(g.vertexCount)          // 4
print(g.edgeCount)            // 4
print(g.isAdjacent(u: 0, v: 1)) // true
print(g.indegree(vertex: 3))  // 2
```

---

## Core Concepts

### Graph Protocols

The library is structured as a layered protocol hierarchy. Every layer adds specific capabilities:

| Protocol | Responsibility |  
|---|---|  
| `Graph` | Kind (directed / undirected) |  
| `VertexListGraph` | `vertexCount`, `vertices`, `index(of:)` |  
| `EdgeListGraph` | `edgeCount`, `edges` |  
| `IncidenceGraph` | `degree`, `adjacent(of:)`, `isAdjacent`, `adjacentEdges`, `source`, `target` |  
| `BidirectionalGraph` | `indegree`, `inEdges` |  
| `PropertyGraph` | Read/write subscripts for vertex and edge properties |  
| `MutableGraph` | `addVertex`, `removeVertex`, `addEdge`, `removeEdge`, `removeAllAdjacentEdges` |  
| `NetworkFlowGraph` | Flow-specific vertex/edge attribute API, `source`/`sink` indices |  

Algorithms are written against the minimal protocol they need:

```swift
// topologicalSort only requires IncidenceGraph & VertexListGraph
public func topologicalSort<G: IncidenceGraph & VertexListGraph>(graph: G) -> [G.Vertex]
```

### Vertices

A vertex in `AdjacentGraph<V, W>` is a value of type `V` stored at a zero-based integer index. The index is stable as long as no vertex with a lower index is removed.

Built-in vertex attribute types:

| Type | When to use |  
|---|---|  
| `Int`, `String`, … | Simple scalar identity |  
| `LabeledVertex` | Named nodes (symbol graphs) |  
| `AnnotatedVertex` | Prototype/exploratory graphs with freeform metadata |  
| `FlowVertex` | Flow networks (carries `excess`, `height`, `supply`) |  

Implement `VertexAttributesProtocol` to define your own:

```swift
public struct CityNode: VertexAttributesProtocol {
    public var label: String
    public var population: Int
    public var isCapital: Bool
}
```

### Edges

An `Edge` is a lightweight struct holding source and target vertex indices:

```swift
public struct Edge: Codable, Hashable, Sendable {
    public var u: Int   // source
    public var v: Int   // target
    public func reversed() -> Edge
}
```

Edge metadata is stored separately in `AdjacentGraph.edgeProperties: [Edge: W]`.

Built-in edge attribute types:

| Type | When to use |  
|---|---|  
| `NoProperty` | Structural/unweighted graphs |  
| `Double`, `Int`, … | Simple scalar weights |  
| `WeightedEdge` | Named weighted edges |  
| `AnnotatedEdge` | Prototype edges with freeform metadata |  
| `FlowEdge` | Flow arcs with `capacity`, `flow`, `cost`, `lowerBound` |  

### Property Maps

`PropertyMap<Key, Value>` is a dictionary-backed implementation of the `ReadWritePropertyMap` protocol, used internally by BFS/DFS for colour maps and externally by callers who need per-vertex scratch storage:

```swift
var colorMap = PropertyMap<Int, VertexColor>()
graph.vertices.forEach { colorMap.put(key: $0, value: .white) }
```

---

## Graph Construction

### Empty graph

```swift
var g = AdjacentGraph<Int, NoProperty>()                  // directed (default)
var g = AdjacentGraph<Int, NoProperty>(kind: .undirected)
```

### From a vertex list

```swift
let g = AdjacentGraph<String, NoProperty>(vertices: ["S", "A", "B", "T"])
```

### From vertices + edge list

```swift
let g = AdjacentGraph<Int, NoProperty>(
    vertices: Array(0..<4),
    edges: [(0,1), (1,2), (2,3)]
)
```

### From a complete adjacency list

```swift
let adjacency: [[Int]] = [
    [1, 2],   // neighbours of vertex 0
    [2],      // neighbours of vertex 1
    []        // neighbours of vertex 2
]
let g = AdjacentGraph<Int, NoProperty>(
    vertices: [0, 1, 2],
    adacency: adjacency
)
```

### From string-pair tuples (symbol graph)

Vertices are inferred automatically from the endpoint strings.

```swift
let g = AdjacentGraph<String, NoProperty>([
    ("JFK", "LAX"), ("JFK", "ORD"), ("LAX", "SFO")
])
```

### From weighted string-triple tuples

```swift
let g = AdjacentGraph<String, Double>([
    ("A", "B", "1.5"),
    ("B", "C", "2.3"),
])
```

---

## Structural Mutations

```swift
// Add vertices
let idx = g.addVertex(v: "NewNode")

// Remove a vertex (re-indexes remaining vertices)
g.removeVertex(v: "OldNode")

// Add / remove edges
_ = g.addEdge(u: 0, v: 3)
g.removeEdge(u: 0, v: 3)

// Remove all outgoing edges from a vertex
g.removeAllAdjacentEdges(of: 2)
```

> **Note:** `removeVertex` is O(V + E) because all index references must be updated after removal.

---

## Read/Write Vertex & Edge Properties

### Vertex values

```swift  
// Read  
let name: String = g[0]  
let name: String = g.vertexValue(at: 0)  

// Write  
g[0] = "UpdatedName"  
g.setVertexValue("UpdatedName", at: 0)  

// Bulk transform  
g.mapVertices { city in CityNode(label: city.label.uppercased(), population: city.population) }  
```

### Edge properties

```swift  
let e = Edge(u: 0, v: 1)  

// Force-unwrap read (edge must exist)
let w: Double = g[e]

// Safe optional read/write
let w: Double? = g[safe: e]
g[safe: e] = 3.14

// Named API
let w: Double? = g.edgeProperty(for: e)
g.setEdgeProperty(3.14, for: e)

// Bulk transform
g.mapEdges { $0 * 2.0 }
```

### Source and target vertices of an edge

```swift
let cityA = g.source(edge: e)  // V at e.u
let cityB = g.target(edge: e)  // V at e.v
```

---

## Algorithms

### Depth-First Search

```swift  
typealias G = AdjacentGraph<Int, NoProperty>  
let graph = G(vertices: Array(0..<13), edges: myEdges)  

var colorMap = PropertyMap<Int, VertexColor>()  
graph.vertices.forEach { colorMap.put(key: $0, value: .white) }

let visitor = AccumulatorVisitor<Int>()
depthFirstSearch(graph: graph, startVertex: 0, colorMap: &colorMap, visitor: visitor)  

print(visitor.accumulator)  // post-order vertex sequence  
```

Implement `Visitor` to run custom logic on each vertex:

```swift
class MyVisitor: Visitor {
    func visit(vertex: Int) { /* … */ }
}
```

### Breadth-First Search

```swift
var colorMap = PropertyMap<Int, VertexColor>()
let visitor = AccumulatorVisitor<Int>()
breadthFirstSearch(graph: graph, startVertex: 2, colorMap: &colorMap, visitor: visitor)
```

### Topological Sort

Works on directed acyclic graphs (DAGs). Asserts if a cycle is detected.

```swift
let order = topologicalSort(graph: dag)
// order[0] is the first vertex to be fully processed (a leaf in the DAG)
```

### Connectivity Helpers

These are available on all `AdjacentGraph` instances:

```swift
// Set of vertex indices reachable from a start vertex via BFS
let reachable: Set<Int> = g.reachable(from: 0)

// Quick yes/no path existence test
let connected: Bool = g.isConnected(from: 0, to: 5)

// Weakly-connected components (follows outgoing edges only)
let components: [[Int]] = g.connectedComponents()
```

---

## Network Flow

### FlowVertex & FlowEdge

```swift
// A vertex in a flow network
let source = FlowVertex(label: "S", supply: 20)
let sink   = FlowVertex(label: "T", supply: -20)

// A flow arc
let arc = FlowEdge(capacity: 10, flow: 0, cost: 1, lowerBound: 0)
print(arc.residualCapacity)  // 10
print(arc.isSaturated)       // false
```

`FlowEdge.flow` is automatically clamped to `[lowerBound, capacity]` on every write.

### Building a Flow Network

Use the `FlowNetwork` type alias (`AdjacentGraph<FlowVertex, FlowEdge>`):

```swift
var net = FlowNetwork()

let s = net.addVertex(v: FlowVertex(label: "S"))
let a = net.addVertex(v: FlowVertex(label: "A"))
let b = net.addVertex(v: FlowVertex(label: "B"))
let t = net.addVertex(v: FlowVertex(label: "T"))

_ = net.addEdge(u: s, v: a)
_ = net.addEdge(u: s, v: b)
_ = net.addEdge(u: a, v: t)
_ = net.addEdge(u: b, v: t)
_ = net.addEdge(u: a, v: b)

net.setEdgeAttributes(FlowEdge(capacity: 10), for: Edge(u: s, v: a))
net.setEdgeAttributes(FlowEdge(capacity: 5),  for: Edge(u: s, v: b))
net.setEdgeAttributes(FlowEdge(capacity: 10), for: Edge(u: a, v: t))
net.setEdgeAttributes(FlowEdge(capacity: 5),  for: Edge(u: b, v: t))
net.setEdgeAttributes(FlowEdge(capacity: 3),  for: Edge(u: a, v: b))
```

### Ford-Fulkerson Max-Flow

```swift
let (maxFlowValue, resultNetwork) = maxFlow(in: net, from: s, to: t)
print("Max flow: \(maxFlowValue)")  // 15.0

// Inspect final flow on each arc
for edge in resultNetwork.edges {
    if let attr = resultNetwork.edgeAttributes(for: edge) {
        print("\(edge): flow=\(attr.flow) / capacity=\(attr.capacity)")
    }
}
```

The original network is **not mutated**; `maxFlow` returns a new copy with final flow values.

### Custom Flow Networks

Any `AdjacentGraph<V, FlowEdge>` where `V: VertexAttributesProtocol` automatically conforms to `NetworkFlowGraph`. Implement your own vertex type for domain-specific annotations:

```swift
struct PipeNode: VertexAttributesProtocol {
    var label: String
    var pressure: Double
    var isValveOpen: Bool
}

typealias PipeNetwork = AdjacentGraph<PipeNode, FlowEdge>
var pipes = PipeNetwork(vertices: [ PipeNode(label: "Pump", pressure: 100, isValveOpen: true), … ])
```

---

## Graph Generators

Pre-built graph topologies are available as static factory enums:

```swift
// Star graph (hub and spokes)
let star = StarGraph<Int>.build(withCenter: 0, andLeafs: [1, 2, 3, 4])

// Complete graph (every vertex connected to every other)
let k5 = CompleteGraph<String>.build(vertices: ["A","B","C","D","E"])

// Path graph  0—1—2—3—4
let path = PathGraph<Int>.withPath(Array(0..<5))

// Cycle graph  0—1—2—3—0
let cycle = CycleGraph<Int>.withCycle(Array(0..<4))

// Random graph (V vertices, E edges)
let random = try RandomGraph.build(vertex: 10, edge: 15)

// Erdős–Rényi random graph
let er = try RandomGraph.build(vertex: 20, probability: 0.3)

// Bipartite random graphs
let bip = try BipartiteRandomGraph.build(partition: 5, partition: 5, edge: 8)
```

---

## File Import

### Unweighted graph text format

```
13     ← vertex count
15     ← edge count
0 5    ← edges (one per line)
...
```

```swift
var g = AdjacentGraph<Int, NoProperty>()
let data = try readBundle(file: "tinyDG", ofType: "txt", separator: " ")
g.initialize(unweightedGraph: data)
```

### Weighted graph text format

```
8
15
4 5 0.35
...
```

```swift
var g = AdjacentGraph<Int, Double>()
let data = try readBundle(file: "tinyEWD", ofType: "txt", separator: " ")
g.initializeGraph(weightedGraph: data)
```

### CSV / symbol graph

```swift
let data = try readBundle(file: "usa-map", ofType: "csv", separator: ",")
    .map { $0.splat3() }
let g = AdjacentGraph<String, Int>(data)
```

---

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hakkabon/NetworkGraph.git", branch: "main"),
],
targets: [
    .target(
        name: "MyApp", 
        dependencies: [
            .product(name: "NetworkGraph", package: "NetworkGraph"),
        ]
    ),
]
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.
