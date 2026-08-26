# Core Architecture Reference

## Graph Protocols

`NetworkGraph` layers graph capabilities via a clean protocol hierarchy. Algorithms depend only on the protocols they need, making them reusable across any conforming graph type.

```
Graph
 ├── VertexListGraph       vertexCount, vertices[], index(of:)
 ├── EdgeListGraph         edgeCount, edges[]
 └── IncidenceGraph        degree, adjacent(of:), isAdjacent, adjacentEdges
      └── BidirectionalGraph   indegree, inEdges(vertex:)
           └── MutableGraph     addVertex, removeVertex, addEdge, removeEdge
                └── PropertyGraph   vertex/edge subscript read/write
                     └── AdjacentGraph<V, W>  (concrete implementation)
```

### NetworkFlowGraph

An additional protocol layered on top of `PropertyGraph` that provides flow-specific attribute access:

```swift
public protocol NetworkFlowGraph: PropertyGraph {
    var source: Int { get set }
    var sink: Int { get set }
    func flowEdgeAttributes(for: Edge) -> FlowEdge?
    mutating func setFlowEdgeAttributes(_ attr: FlowEdge, for edge: Edge)
}
```

Any `AdjacentGraph<V, FlowEdge>` where `V: VertexAttributesProtocol` automatically synthesizes this conformance.

---

## `AdjacentGraph<V, W>`

The single concrete graph type. Parameterized by:
- `V` — vertex value type, conforming to `VertexAttributesProtocol` (or any `Hashable & Codable & Sendable` scalar)
- `W` — edge property type, conforming to `EdgeAttributesProtocol` (or any `Hashable & Codable & Sendable` scalar, including `NoProperty`)

### Internal Storage

| Property | Type | Purpose |
|---|---|---|
| `vertices` | `[V]` | Vertex values, indexed 0-based |
| `adjacent` | `[Int: [Int]]` | Adjacency list: vertex → outgoing neighbour indices |
| `incoming` | `[Int: [(Int, W?)]]` | Reverse adjacency: vertex → (predecessor, optional property) |
| `edgeProperties` | `[Edge: W]` | Edge weight/attribute dictionary |
| `kind` | `GraphKind` | `.directed` or `.undirected` |

**Undirected graph invariant:** `addEdge(u:v:)` automatically inserts both `(u, v)` and `(v, u)` into `adjacent` and `incoming`. Setting `g[Edge(u:v:)] = w` on an undirected graph symmetrically sets both directions.

---

## Vertex Types

All conform to `VertexAttributesProtocol: Hashable & Codable & Sendable`:

| Type | Fields | Use Case |
|---|---|---|
| `Int`, `String`, … | scalar | Simple identity labels |
| `LabeledVertex` | `label: String` | Symbol graphs (airports, cities) |
| `AnnotatedVertex` | `label`, `userInfo: [String: String]` | Freeform exploratory graphs |
| `FlowVertex` | `label`, `excess`, `height`, `supply` | Flow network vertices |
| Custom struct | Your fields | Domain-specific models |

### Custom vertex type

```swift
public struct CityNode: VertexAttributesProtocol {
    public var label: String
    public var population: Int
    public var isCapital: Bool
    public init(label: String, population: Int = 0, isCapital: Bool = false) {
        self.label = label
        self.population = population
        self.isCapital = isCapital
    }
}

typealias CityGraph = AdjacentGraph<CityNode, Double>
```

---

## Edge Types

All conform to `EdgeAttributesProtocol: Hashable & Codable & Sendable`:

| Type | Fields | Use Case |
|---|---|---|
| `NoProperty` | — | Topology-only (unweighted) graphs |
| `Double`, `Int`, `Float` | scalar | Simple numeric weights |
| `WeightedEdge` | `label`, `weight: Double` | Named weighted edges |
| `AnnotatedEdge` | `label`, `userInfo` | Freeform metadata arcs |
| `FlowEdge` | `label`, `capacity`, `flow`, `cost`, `lowerBound` | Network flow arcs |

### `FlowEdge` Details

```swift
public struct FlowEdge: EdgeAttributesProtocol {
    public var capacity: Double      // maximum throughput
    public var flow: Double          // current flow (clamped to [lowerBound, capacity])
    public var cost: Double          // cost per unit of flow (for min-cost flow)
    public var lowerBound: Double    // minimum required flow

    // Derived
    public var residualCapacity: Double { capacity - flow }
    public var isSaturated: Bool { flow >= capacity }
}
```

---

## Graph Construction

### Initializers

```swift
// Empty directed graph
var g = AdjacentGraph<Int, NoProperty>()

// Empty undirected graph
var g = AdjacentGraph<String, Double>(kind: .undirected)

// From vertex list
var g = AdjacentGraph<String, NoProperty>(vertices: ["A", "B", "C"])

// From vertex list + edge pairs
var g = AdjacentGraph<Int, NoProperty>(
    vertices: Array(0..<5),
    edges: [(0,1), (1,2), (2,3), (3,4)]
)

// From weighted string-triple tuples (CSV-style)
var g = AdjacentGraph<String, Double>([
    ("A", "B", "1.5"),
    ("B", "C", "2.3"),
])

// From pair tuples (auto-deduplicates vertices)
var g = AdjacentGraph<String, NoProperty>([
    ("JFK", "LAX"), ("JFK", "ORD"), ("ORD", "SFO")
])
```

---

## Structural Mutations

```swift
// Add a vertex; returns its new index
let idx = g.addVertex(v: "NewNode")

// Remove a vertex (O(V + E) — re-indexes all higher indices)
g.removeVertex(v: "OldNode")

// Add / remove an edge
let added = g.addEdge(u: 0, v: 3)  // returns Bool (false if already exists)
g.removeEdge(u: 0, v: 3)

// Remove all outgoing edges from a vertex
g.removeAllAdjacentEdges(of: 2)
```

---

## Property Access

### Vertex properties

```swift
// Read
let name: String = g[0]
let name: String = g.vertexValue(at: 0)

// Write
g[0] = "UpdatedName"
g.setVertexValue("UpdatedName", at: 0)

// Bulk transform (returns new graph — value semantics)
let upper = g.mapVertices { v in v.uppercased() }
```

### Edge properties

```swift
let e = Edge(u: 0, v: 1)

// Force-unwrap read (edge must exist)
let w: Double = g[e]

// Safe optional
let w: Double? = g[safe: e]
g[safe: e] = 3.14

// Named API
let w: Double? = g.edgeProperty(for: e)
g.setEdgeProperty(3.14, for: e)

// Bulk transform
g.mapEdges { $0 * 2.0 }
```

---

## Query API

```swift
g.vertexCount                     // Int
g.edgeCount                       // Int (each undirected edge counted once)
g.degree(vertex: i)               // Int — outgoing degree
g.indegree(vertex: i)             // Int — incoming degree
g.adjacent(of: i)                 // [Int] — outgoing neighbour indices
g.inEdges(vertex: i)              // [(Int, W?)] — (source, property)
g.isAdjacent(u: i, v: j)         // Bool
g.source(edge: e)                 // V
g.target(edge: e)                 // V
g.edges                           // [Edge] — all edges
g.reachable(from: i)              // Set<Int> — BFS reachability
g.isConnected(from: i, to: j)    // Bool
g.connectedComponents()           // [[Int]]
```

---

## Classical Algorithms (pre-extension)

### Topological Sort

For directed acyclic graphs; asserts if a cycle is detected:

```swift
let order = topologicalSort(graph: dag)
// Vertices in reverse topological order (leaves first)
```

### Depth-First & Breadth-First Search

Using the visitor protocol:

```swift
var colorMap = PropertyMap<Int, VertexColor>()
g.vertices.forEach { colorMap.put(key: $0, value: .white) }

let visitor = AccumulatorVisitor<Int>()
depthFirstSearch(graph: g, startVertex: 0, colorMap: &colorMap, visitor: visitor)
breadthFirstSearch(graph: g, startVertex: 0, colorMap: &colorMap, visitor: visitor)
```

Implement `Visitor` for custom event handling:

```swift
class MyVisitor: Visitor {
    func discoverVertex(_ v: Int) { /* on first visit */ }
    func finishVertex(_ v: Int)   { /* post-order */    }
    func examineEdge(_ e: Edge)   { /* on edge relax */ }
}
```

---

## PropertyMap

Dictionary-backed scratch storage used by BFS/DFS internally and available externally:

```swift
var distMap = PropertyMap<Int, Double>()
distMap.put(key: 3, value: 0.0)
let d: Double = distMap.get(key: 3)!
```

Conforms to `ReadWritePropertyMap`.

---

## File Import

### Text format (Sedgewick-style)

```
13
15
0 5
4 3
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
