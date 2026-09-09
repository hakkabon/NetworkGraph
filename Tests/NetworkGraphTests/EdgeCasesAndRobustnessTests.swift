//
//  EdgeCasesAndRobustnessTests.swift
//  NetworkGraphTests
//
//  Created for NetworkGraph elevation review verification.
//

import XCTest
@testable import NetworkGraph

final class EdgeCasesAndRobustnessTests: XCTestCase {

    // MARK: - 1. addEdge on Invalid Vertex Throws NetworkGraphError.invalidVertex

    func testAddEdgeInvalidVertexThrows() {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .directed)
        XCTAssertThrowsError(try g.addEdge(u: -1, v: 1)) { error in
            guard case NetworkGraphError.invalidVertex(let index, let size) = error else {
                XCTFail("Expected invalidVertex, got \(error)")
                return
            }
            XCTAssertEqual(index, -1)
            XCTAssertEqual(size, 3)
        }

        XCTAssertThrowsError(try g.addEdge(u: 0, v: 5)) { error in
            guard case NetworkGraphError.invalidVertex(let index, let size) = error else {
                XCTFail("Expected invalidVertex, got \(error)")
                return
            }
            XCTAssertEqual(index, 5)
            XCTAssertEqual(size, 3)
        }
    }

    // MARK: - 2. isAdjacent and edgeCount Consistency After removeEdge

    func testIsAdjacentAndEdgeCountAfterRemoveEdge() throws {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 10.0
        _ = try g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 20.0
        _ = try g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 30.0

        XCTAssertEqual(g.edgeCount, 6) // undirected: 3 pairs = 6 directed arcs in adjacent
        XCTAssertTrue(g.isAdjacent(u: 0, v: 1))
        XCTAssertTrue(g.isAdjacent(u: 1, v: 0))

        // Remove edge (0, 1) using reversed orientation
        g.removeEdge(u: 1, v: 0)

        XCTAssertFalse(g.isAdjacent(u: 0, v: 1))
        XCTAssertFalse(g.isAdjacent(u: 1, v: 0))
        XCTAssertEqual(g.edgeCount, 4)
        XCTAssertNil(g[safe: Edge(u: 0, v: 1)])
        XCTAssertNil(g[safe: Edge(u: 1, v: 0)])
    }

    // MARK: - 3. removeVertex Followed by Algorithm Execution

    func testRemoveVertexThenRunAlgorithms() throws {
        // Chain: 0 - 1 - 2 - 3
        var g = AdjacentGraph<String, Double>(vertices: ["A", "B", "C", "D"], kind: .undirected)
        _ = try g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 1.0
        _ = try g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 1.0

        XCTAssertEqual(g.vertexCount, 4)
        XCTAssertEqual(g.index(of: "B"), 1)

        // Remove vertex "B" (index 1)
        g.removeVertex(v: "B")

        XCTAssertEqual(g.vertexCount, 3)
        XCTAssertEqual(g.vertices, ["A", "C", "D"])
        XCTAssertEqual(g.index(of: "A"), 0)
        XCTAssertEqual(g.index(of: "C"), 1)
        XCTAssertEqual(g.index(of: "D"), 2)
        XCTAssertNil(g.index(of: "B"))

        // Edge (C, D) was formerly (2, 3), now shifted to (1, 2)
        XCTAssertTrue(g.isAdjacent(u: 1, v: 2))
        XCTAssertFalse(g.isAdjacent(u: 0, v: 1)) // A is no longer connected to C

        // Running connected components on modified graph: should produce 2 components [A] and [C, D]
        let components = Connectivity.connectedComponents(g)
        XCTAssertEqual(components.count, 2)
    }

    // MARK: - 4. Disconnected Graph BFS & DFS Multi-Component Traversal

    func testDisconnectedGraphDFSAndBFS() throws {
        // Two disjoint components: {0, 1} and {2, 3}
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try g.addEdge(u: 0, v: 1)
        _ = try g.addEdge(u: 2, v: 3)

        // BFS from 0 only visits its own component
        let bfsRes = Connectivity.bfs(graph: g, startVertex: 0)
        XCTAssertEqual(Set(bfsRes.visitorOrder), Set([0, 1]))
        XCTAssertNil(bfsRes.distances[2])

        // Full DFS visits all vertices across all components
        let dfsRes = Connectivity.dfs(graph: g)
        XCTAssertEqual(dfsRes.visitorOrder.count, 4)
        for t in dfsRes.discoveryTimes {
            XCTAssertGreaterThan(t, 0)
        }
    }

    // MARK: - 5. Negative Cycle Bellman-Ford Error Detection

    func testBellmanFordNegativeCycleThrows() throws {
        // Directed graph with negative weight cycle: 0 -> 1 (1.0), 1 -> 2 (-5.0), 2 -> 0 (1.0) => cycle sum = -3.0
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2], kind: .directed)
        _ = try g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = -5.0
        _ = try g.addEdge(u: 2, v: 0); g[Edge(u: 2, v: 0)] = 1.0

        XCTAssertThrowsError(try PathsAndCycles.bellmanFord(graph: g, source: 0)) { error in
            guard case NetworkGraphError.negativeCycle = error else {
                XCTFail("Expected NetworkGraphError.negativeCycle, got \(error)")
                return
            }
        }
    }

    // MARK: - 6. Empty Graph Corner Cases

    func testEmptyGraphCornerCases() {
        let empty = AdjacentGraph<Int, Double>(vertices: [], kind: .directed)
        XCTAssertEqual(empty.vertexCount, 0)
        XCTAssertEqual(empty.edgeCount, 0)
        XCTAssertTrue(Connectivity.isConnected(empty))
        XCTAssertNil(PathsAndCycles.eulerCircuit(empty))
        XCTAssertEqual(Connectivity.allMaximalCliques(empty), [])

        var colorMap = PropertyMap<Int, VertexColor>()
        let visitor = PrintVisitor()
        depthFirstSearch(graph: empty, startVertex: 0, colorMap: &colorMap, visitor: visitor)
        breadthFirstSearch(graph: empty, startVertex: 0, colorMap: &colorMap, visitor: visitor)
    }

    // MARK: - 7. DisjointSet.union of Same Set Returns False

    func testDisjointSetUnionOfSameSetReturnsFalse() {
        var ds = DisjointSet(size: 5)
        XCTAssertEqual(ds.count, 5)

        XCTAssertTrue(ds.union(0, 1))
        XCTAssertEqual(ds.count, 4)

        // Redundant union of elements already in the same set
        XCTAssertFalse(ds.union(0, 1))
        XCTAssertEqual(ds.count, 4)

        XCTAssertTrue(ds.union(1, 2))
        XCTAssertEqual(ds.count, 3)

        // 0 and 2 are transitively connected
        XCTAssertFalse(ds.union(0, 2))
        XCTAssertEqual(ds.count, 3)
    }

    // MARK: - 8. Visitor Traversal Integration

    func testVisitorTraversalIntegration() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .directed)
        _ = try g.addEdge(u: 0, v: 1)
        _ = try g.addEdge(u: 1, v: 2)

        // Test closure visitor callback
        var dfsOrder: [Int] = []
        _ = Connectivity.dfs(graph: g, startVertex: 0) { v in
            dfsOrder.append(v)
        }
        XCTAssertEqual(dfsOrder, [0, 1, 2])

        // Test AccumulatorVisitor conformance
        let visitor = AccumulatorVisitor<Int>()
        _ = Connectivity.bfs(graph: g, startVertex: 0, visitor: visitor)
        XCTAssertEqual(visitor.accumulator, [0, 1, 2])
    }

    // MARK: - 9. Corrected Adjacency Initializer Spelling

    func testAdjacencyInitializerSpelling() {
        let g = AdjacentGraph<Int, NoProperty>(
            vertices: [0, 1, 2],
            adjacency: [[1], [2], []],
            kind: .directed
        )
        XCTAssertEqual(g.vertexCount, 3)
        XCTAssertEqual(g.edgeCount, 2)
        XCTAssertTrue(g.isAdjacent(u: 0, v: 1))
        XCTAssertTrue(g.isAdjacent(u: 1, v: 2))
    }
}
