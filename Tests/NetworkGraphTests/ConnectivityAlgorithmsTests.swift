//
//  ConnectivityAlgorithmsTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class ConnectivityAlgorithmsTests: XCTestCase {

    func test2_1_HararyGraphs() throws {
        let h4_6 = try Connectivity.hararyGraph(k: 4, n: 6)
        XCTAssertEqual(h4_6.vertexCount, 6)
        for v in 0..<6 {
            XCTAssertGreaterThanOrEqual(h4_6.degree(vertex: v), 4)
        }
    }

    func test2_2_DFSClassification() {
        // Triangle with chord: 0 -> 1, 1 -> 2, 2 -> 0, 0 -> 2
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 2, v: 0)
        _ = try! g.addEdge(u: 0, v: 2)

        let res = Connectivity.dfs(graph: g, startVertex: 0)
        XCTAssertEqual(res.edgeTypes[Edge(u: 0, v: 1)], .tree)
        XCTAssertEqual(res.edgeTypes[Edge(u: 1, v: 2)], .tree)
        XCTAssertEqual(res.edgeTypes[Edge(u: 2, v: 0)], .back)
        XCTAssertEqual(res.edgeTypes[Edge(u: 0, v: 2)], .forward)
    }

    func test2_3_BFS() {
        // 0 -> 1 -> 3, 0 -> 2 -> 3
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3], kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 0, v: 2)
        _ = try! g.addEdge(u: 1, v: 3)
        _ = try! g.addEdge(u: 2, v: 3)

        let bfs = Connectivity.bfs(graph: g, startVertex: 0)
        XCTAssertEqual(bfs.distances[0], 0)
        XCTAssertEqual(bfs.distances[1], 1)
        XCTAssertEqual(bfs.distances[2], 1)
        XCTAssertEqual(bfs.distances[3], 2)
        XCTAssertEqual(bfs.layers.count, 3)
    }

    func test2_4_2_5_ConnectedComponents() {
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<6), kind: .undirected)
        // Comp 1: 0-1-2
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        // Comp 2: 3-4
        _ = try! g.addEdge(u: 3, v: 4)
        // Comp 3: 5 isolated

        XCTAssertFalse(Connectivity.isConnected(g))
        let comps = Connectivity.connectedComponents(g)
        XCTAssertEqual(comps.count, 3)
        XCTAssertEqual(comps[0], [0, 1, 2])
        XCTAssertEqual(comps[1], [3, 4])
        XCTAssertEqual(comps[2], [5])
    }

    func test2_6_CutNodesAndBridges() {
        // Bowtie graph: (0-1-2-0) and (2-3-4-2), vertex 2 is articulation point
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<5), kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 2, v: 0)
        _ = try! g.addEdge(u: 2, v: 3)
        _ = try! g.addEdge(u: 3, v: 4)
        _ = try! g.addEdge(u: 4, v: 2)

        let cuts = Connectivity.findCutNodesAndBridges(g)
        XCTAssertTrue(cuts.articulationPoints.contains(2))
        XCTAssertEqual(cuts.articulationPoints.count, 1)
        XCTAssertEqual(cuts.bridges.count, 0)

        // Add a pendant edge 4-5 (bridge)
        _ = g.addVertex(v: 5)
        _ = try! g.addEdge(u: 4, v: 5)
        let cutsWithBridge = Connectivity.findCutNodesAndBridges(g)
        XCTAssertTrue(cutsWithBridge.bridges.contains(Edge(u: 4, v: 5)))
        XCTAssertTrue(cutsWithBridge.articulationPoints.contains(4))
    }

    func test2_7_StronglyConnectedComponents() {
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<5), kind: .directed)
        // SCC 1: 0 -> 1 -> 2 -> 0
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 2, v: 0)
        // 2 -> 3
        _ = try! g.addEdge(u: 2, v: 3)
        // SCC 2: 3 -> 4 -> 3
        _ = try! g.addEdge(u: 3, v: 4)
        _ = try! g.addEdge(u: 4, v: 3)

        let scc = Connectivity.stronglyConnectedComponents(g)
        XCTAssertEqual(scc.components.count, 2)
        XCTAssertEqual(scc.condensationDAG.vertexCount, 2)
        XCTAssertEqual(scc.condensationDAG.edgeCount, 1)
    }

    func test2_8_MinimalEquivalentGraph() {
        // 0 -> 1 -> 2 and redundant 0 -> 2
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 0, v: 2)

        let meg = Connectivity.minimalEquivalentGraph(g)
        XCTAssertEqual(meg.edgeCount, 2)
        XCTAssertFalse(meg.isAdjacent(u: 0, v: 2))
        XCTAssertTrue(meg.isAdjacent(u: 0, v: 1))
        XCTAssertTrue(meg.isAdjacent(u: 1, v: 2))
    }

    func test2_9_GlobalMinCut() {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        // Two clusters: (0, 1) and (2, 3) connected by a single weak edge (1, 2) of weight 1
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 10.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 10.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 1.0

        let (minCut, partition) = Connectivity.globalMinCut(graph: g)
        XCTAssertEqual(minCut, 1.0)
        XCTAssertTrue(partition == [0, 1] || partition == [2, 3])
    }

    func test2_10_MinimumSpanningTree() {
        var g = AdjacentGraph<Int, Double>(vertices: Array(0..<4), kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 2.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 3.0
        _ = try! g.addEdge(u: 0, v: 3); g[Edge(u: 0, v: 3)] = 10.0
        _ = try! g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 5.0

        let mst = Connectivity.minimumSpanningTree(graph: g)
        XCTAssertEqual(mst.edges.count, 3)
        XCTAssertEqual(mst.totalWeight, 6.0)
    }

    func test2_11_AllCliques() {
        // Complete graph K4
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<4), kind: .undirected)
        for i in 0..<4 {
            for j in (i + 1)..<4 {
                _ = try! g.addEdge(u: i, v: j)
            }
        }

        let cliques = Connectivity.allMaximalCliques(g)
        XCTAssertEqual(cliques.count, 1)
        XCTAssertEqual(cliques[0], [0, 1, 2, 3])
        XCTAssertEqual(Connectivity.maximumClique(g), [0, 1, 2, 3])
    }
}
