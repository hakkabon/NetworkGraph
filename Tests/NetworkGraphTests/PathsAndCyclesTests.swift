//
//  PathsAndCyclesTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class PathsAndCyclesTests: XCTestCase {

    func test3_1_FundamentalCycles() {
        // Complete K4 has 4 vertices, 6 edges, so 6 - 4 + 1 = 3 fundamental cycles
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<4), kind: .undirected)
        for i in 0..<4 {
            for j in (i + 1)..<4 {
                _ = try! g.addEdge(u: i, v: j)
            }
        }

        let cycles = PathsAndCycles.fundamentalCycles(g)
        XCTAssertEqual(cycles.count, 3)
    }

    func test3_2_Girth() {
        // 4-cycle: 0-1-2-3-0 (girth = 4)
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<4), kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 2, v: 3)
        _ = try! g.addEdge(u: 3, v: 0)

        XCTAssertEqual(PathsAndCycles.girth(g), 4)

        // Add a triangle chord: 0-2 (now girth = 3)
        _ = try! g.addEdge(u: 0, v: 2)
        XCTAssertEqual(PathsAndCycles.girth(g), 3)
    }

    func test3_3_BidirectionalDijkstra() {
        var g = AdjacentGraph<Int, Double>(vertices: Array(0..<5), kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 2.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 3.0
        _ = try! g.addEdge(u: 2, v: 4); g[Edge(u: 2, v: 4)] = 1.0
        _ = try! g.addEdge(u: 0, v: 3); g[Edge(u: 0, v: 3)] = 10.0
        _ = try! g.addEdge(u: 3, v: 4); g[Edge(u: 3, v: 4)] = 1.0

        let result = PathsAndCycles.bidirectionalDijkstra(graph: g, source: 0, target: 4)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.distance, 6.0)
        XCTAssertEqual(result!.path, [0, 1, 2, 4])
    }

    func test3_4_BellmanFord() throws {
        var g = AdjacentGraph<Int, Double>(vertices: Array(0..<4), kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 2.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 3.0
        _ = try! g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 5.0

        let (dist, _) = try PathsAndCycles.bellmanFord(graph: g, source: 0)
        XCTAssertEqual(dist[0], 0.0)
        XCTAssertEqual(dist[1], 1.0)
        XCTAssertEqual(dist[2], 3.0)
        XCTAssertEqual(dist[3], 6.0)
    }

    func test3_6_FloydWarshall() {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2], kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 3.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 4.0
        _ = try! g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 10.0

        let apsp = PathsAndCycles.floydWarshall(graph: g)
        XCTAssertEqual(apsp.distances[0][2], 7.0)
        XCTAssertEqual(apsp.path(from: 0, to: 2), [0, 1, 2])
    }

    func test3_7_3_8_KShortestPaths() {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .directed)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try! g.addEdge(u: 1, v: 3); g[Edge(u: 1, v: 3)] = 1.0
        _ = try! g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 2.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 2.0
        _ = try! g.addEdge(u: 0, v: 3); g[Edge(u: 0, v: 3)] = 10.0

        let kPaths = PathsAndCycles.kShortestPaths(graph: g, source: 0, target: 3, k: 3)
        XCTAssertEqual(kPaths.count, 3)
        XCTAssertEqual(kPaths[0].cost, 2.0)
        XCTAssertEqual(kPaths[0].path, [0, 1, 3])
        XCTAssertEqual(kPaths[1].cost, 4.0)
        XCTAssertEqual(kPaths[1].path, [0, 2, 3])
        XCTAssertEqual(kPaths[2].cost, 10.0)
        XCTAssertEqual(kPaths[2].path, [0, 3])
    }

    func test3_9_EulerCircuit() {
        // Complete graph K3 (all degrees = 2) has an Euler circuit
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 2, v: 0)

        let euler = PathsAndCycles.eulerCircuit(g)
        XCTAssertNotNil(euler)
        XCTAssertTrue(euler!.isCircuit)
        XCTAssertEqual(euler!.edges.count, 3)
    }

    func test3_10_HamiltonCycle() {
        // 4-cycle
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 1
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 1
        _ = try! g.addEdge(u: 3, v: 0); g[Edge(u: 3, v: 0)] = 1

        let cycle = PathsAndCycles.hamiltonCycle(g)
        XCTAssertNotNil(cycle)
        XCTAssertEqual(cycle!.count, 5)
        XCTAssertEqual(cycle!.first, cycle!.last)
    }

    func test3_11_ChinesePostman() {
        // Bridge graph: 0-1, 1-2, 2-0 and 2-3 (vertex 3 and 2 have odd degrees)
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 1.0
        _ = try! g.addEdge(u: 2, v: 0); g[Edge(u: 2, v: 0)] = 1.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 2.0

        let postman = PathsAndCycles.chinesePostmanTour(graph: g)
        XCTAssertNotNil(postman)
        XCTAssertTrue(postman!.isCircuit)
        // Original 4 edges + 1 duplicated edge (2-3) = 5 edges
        XCTAssertEqual(postman!.edges.count, 5)
    }

    func test3_12_TravelingSalesman() {
        // Metric TSP on 4 vertices in a square with side 1 and diagonals sqrt(2)
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 1.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 1.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 1.0
        _ = try! g.addEdge(u: 3, v: 0); g[Edge(u: 3, v: 0)] = 1.0
        _ = try! g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 1.414
        _ = try! g.addEdge(u: 1, v: 3); g[Edge(u: 1, v: 3)] = 1.414

        let tsp = PathsAndCycles.travelingSalesman(graph: g)
        XCTAssertEqual(tsp.tour.count, 5)
        XCTAssertEqual(tsp.totalCost, 4.0, accuracy: 0.001)
    }

    func test3_12_ChristofidesTSP() {
        // Metric graph with 5 vertices
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3, 4], kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 2.0
        _ = try! g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 3.0
        _ = try! g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 2.0
        _ = try! g.addEdge(u: 3, v: 4); g[Edge(u: 3, v: 4)] = 3.0
        _ = try! g.addEdge(u: 4, v: 0); g[Edge(u: 4, v: 0)] = 2.0
        _ = try! g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 4.0
        _ = try! g.addEdge(u: 1, v: 3); g[Edge(u: 1, v: 3)] = 4.0
        _ = try! g.addEdge(u: 2, v: 4); g[Edge(u: 2, v: 4)] = 4.0

        let result = PathsAndCycles.christofides(graph: g)
        XCTAssertEqual(result.tour.count, 6)
        XCTAssertEqual(result.tour.first, result.tour.last)
        XCTAssertEqual(Set(result.tour).count, 5)
        XCTAssertLessThanOrEqual(result.totalCost, 12.0)
    }
}
