//
//  PlanarityIsomorphismColoringMatchingTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class PlanarityIsomorphismColoringMatchingTests: XCTestCase {

    // MARK: - Topic 4: Planarity Testing

    func test4_1_PlanarityK4AndK5() {
        // Complete graph K4 is planar
        var k4 = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<4), kind: .undirected)
        for i in 0..<4 {
            for j in (i + 1)..<4 {
                _ = try! k4.addEdge(u: i, v: j)
            }
        }
        XCTAssertTrue(Planarity.isPlanar(k4).isPlanar)

        // Complete graph K5 is NOT planar (Kuratowski's theorem)
        var k5 = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<5), kind: .undirected)
        for i in 0..<5 {
            for j in (i + 1)..<5 {
                _ = try! k5.addEdge(u: i, v: j)
            }
        }
        XCTAssertFalse(Planarity.isPlanar(k5).isPlanar)
    }

    // MARK: - Topic 5: Graph Isomorphism Testing

    func test5_1_GraphIsomorphism() throws {
        // Generate random isomorphic pair and verify isomorphism test detects it
        let pair = try RandomIsomorphicGraph.build(vertex: 6, edge: 8)
        let result = GraphIsomorphism.areIsomorphic(pair.original, pair.permuted)
        XCTAssertTrue(result.isIsomorphic)
        XCTAssertNotNil(result.mapping)

        // Verify that mapping is a valid isomorphism
        for e in pair.original.edges {
            let uMapped = result.mapping![e.u]!
            let vMapped = result.mapping![e.v]!
            XCTAssertTrue(pair.permuted.isAdjacent(u: uMapped, v: vMapped))
        }

        // Test non-isomorphic pair (triangle vs line)
        var g1 = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = try! g1.addEdge(u: 0, v: 1)
        _ = try! g1.addEdge(u: 1, v: 2)
        _ = try! g1.addEdge(u: 2, v: 0)

        var g2 = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = try! g2.addEdge(u: 0, v: 1)
        _ = try! g2.addEdge(u: 1, v: 2)

        XCTAssertFalse(GraphIsomorphism.areIsomorphic(g1, g2).isIsomorphic)
    }

    func test5_1_TreeIsomorphismAHU() throws {
        // Tree 1: 0-1, 1-2, 1-3
        var t1 = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! t1.addEdge(u: 0, v: 1)
        _ = try! t1.addEdge(u: 1, v: 2)
        _ = try! t1.addEdge(u: 1, v: 3)

        // Tree 2 (permuted labels): 3-2, 2-0, 2-1 (root is 2 with 3 leaves)
        var t2 = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! t2.addEdge(u: 3, v: 2)
        _ = try! t2.addEdge(u: 2, v: 0)
        _ = try! t2.addEdge(u: 2, v: 1)

        XCTAssertTrue(GraphIsomorphism.areTreesIsomorphic(t1, t2))
    }

    // MARK: - Topic 6: Coloring & Chromatic Polynomial

    func test6_1_NodeColoring() {
        // Bipartite graph should have chromatic number 2
        var bip = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! bip.addEdge(u: 0, v: 2)
        _ = try! bip.addEdge(u: 0, v: 3)
        _ = try! bip.addEdge(u: 1, v: 2)
        _ = try! bip.addEdge(u: 1, v: 3)

        let resBip = GraphColoring.color(bip)
        XCTAssertEqual(resBip.chromaticNumber, 2)

        // Triangle should have chromatic number 3
        var tri = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = try! tri.addEdge(u: 0, v: 1)
        _ = try! tri.addEdge(u: 1, v: 2)
        _ = try! tri.addEdge(u: 2, v: 0)

        let resTri = GraphColoring.color(tri)
        XCTAssertEqual(resTri.chromaticNumber, 3)

        // Verify valid coloring (no two adjacent vertices have same color)
        for e in tri.edges {
            XCTAssertNotEqual(resTri.colors[e.u], resTri.colors[e.v])
        }
    }

    func test6_2_ChromaticPolynomial() {
        // For tree on n vertices: P(T_n, k) = k * (k - 1)^(n - 1)
        // For n = 3: P(T_3, k) = k * (k - 1)^2 = k^3 - 2k^2 + k
        var tree = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = try! tree.addEdge(u: 0, v: 1)
        _ = try! tree.addEdge(u: 1, v: 2)

        let poly = GraphColoring.chromaticPolynomial(tree)
        // Evaluate at k = 3 -> 3 * 2^2 = 12
        let val3 = GraphColoring.evaluateChromaticPolynomial(poly, at: 3)
        XCTAssertEqual(val3, 12.0, accuracy: 0.001)

        // Evaluate at k = 2 -> 2 * 1^2 = 2
        let val2 = GraphColoring.evaluateChromaticPolynomial(poly, at: 2)
        XCTAssertEqual(val2, 2.0, accuracy: 0.001)
    }

    // MARK: - Topic 7: Graph Matching

    func test7_1_HopcroftKarpBipartiteMatching() {
        // V1 = {0, 1, 2}, V2 = {3, 4, 5}
        // Edges: 0-3, 0-4, 1-3, 2-4, 2-5
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<6), kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 3)
        _ = try! g.addEdge(u: 0, v: 4)
        _ = try! g.addEdge(u: 1, v: 3)
        _ = try! g.addEdge(u: 2, v: 4)
        _ = try! g.addEdge(u: 2, v: 5)

        let matching = GraphMatching.hopcroftKarp(graph: g, partitionV1: [0, 1, 2])
        XCTAssertEqual(matching.cardinality, 3)
        XCTAssertEqual(matching.matchedEdges.count, 3)
    }

    func test7_1_EdmondsBlossomGeneralMatching() {
        // Odd cycle with a stem (classic blossom): 0-1, 1-2, 2-0 (triangle) + 0-3
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = try! g.addEdge(u: 0, v: 1)
        _ = try! g.addEdge(u: 1, v: 2)
        _ = try! g.addEdge(u: 2, v: 0)
        _ = try! g.addEdge(u: 0, v: 3)

        let match = GraphMatching.edmondsBlossom(g)
        XCTAssertEqual(match.cardinality, 2)
    }

    func test7_2_HungarianAssignment() {
        // Cost matrix for 3 workers and 3 jobs:
        // [ [10, 19, 8],
        //   [10, 1, 12],
        //   [13, 12, 14] ]
        // Optimal assignment: 0->2 (8), 1->1 (1), 2->0 (13) = Total cost 22
        let costMatrix: [[Double]] = [
            [10, 19, 8],
            [10, 1, 12],
            [13, 12, 14]
        ]
        let (assignment, totalCost) = GraphMatching.hungarianAssignment(costMatrix: costMatrix)
        XCTAssertEqual(totalCost, 22.0, accuracy: 0.001)
        XCTAssertEqual(assignment, [2, 1, 0])
    }
}
