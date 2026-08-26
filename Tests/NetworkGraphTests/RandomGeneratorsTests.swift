//
//  RandomGeneratorsTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class RandomGeneratorsTests: XCTestCase {

    func test1_1_RandomPermutation() {
        let n = 20
        let perm = RandomPermutation.generate(n: n)
        XCTAssertEqual(perm.count, n)
        XCTAssertEqual(Set(perm).count, n)
        for i in 0..<n {
            XCTAssertTrue(perm.contains(i))
        }
    }

    func test1_2_RandomGraph() throws {
        let V = 10
        let E = 15
        let graph = try RandomGraph.build(vertex: V, edge: E)
        XCTAssertEqual(graph.vertexCount, V)
        XCTAssertEqual(graph.edgeCount, E)

        let gProb = try RandomGraph.build(vertex: 8, probability: 0.5)
        XCTAssertEqual(gProb.vertexCount, 8)
    }

    func test1_3_RandomBipartiteGraph() throws {
        let V1 = 5
        let V2 = 6
        let E = 12
        let graph = try BipartiteRandomGraph.build(partition: V1, partition: V2, edge: E)
        XCTAssertEqual(graph.vertexCount, V1 + V2)
        XCTAssertEqual(graph.edgeCount, E)

        for edge in graph.edges {
            let uInV1 = (edge.u < V1)
            let vInV2 = (edge.v >= V1 && edge.v < V1 + V2)
            XCTAssertTrue(uInV1 && vInV2, "Edge must cross partitions")
        }
    }

    func test1_4_RandomRegularGraph() throws {
        let V = 8
        let d = 3
        let graph = try RandomRegularGraph.build(vertex: V, degree: d)
        XCTAssertEqual(graph.vertexCount, V)
        XCTAssertEqual(graph.edgeCount, (V * d)) // In AdjacentGraph undirected, edgeCount sums all directed arcs (V*d)
        for v in 0..<V {
            XCTAssertEqual(graph.degree(vertex: v), d, "Vertex \(v) must have degree \(d)")
        }
    }

    func test1_5_RandomSpanningTree() throws {
        let V = 10
        let complete = try RandomConnectedGraph.build(vertex: V, edge: 25)
        let tree = try RandomTree.spanningTree(of: complete)
        XCTAssertEqual(tree.vertexCount, V)
        XCTAssertEqual(tree.edgeCount, (V - 1) * 2) // Undirected: 2 directed arcs per tree edge
    }

    func test1_6_RandomLabeledTree() throws {
        let V = 12
        let tree = try RandomTree.labeledTree(vertex: V)
        XCTAssertEqual(tree.vertexCount, V)
        XCTAssertEqual(tree.edgeCount, (V - 1) * 2)
        XCTAssertEqual(tree.connectedComponents().count, 1)
    }

    func test1_7_RandomUnlabeledRootedTree() throws {
        let V = 10
        let tree = try RandomTree.unlabeledRootedTree(vertex: V)
        XCTAssertEqual(tree.vertexCount, V)
        XCTAssertEqual(tree.edgeCount, V - 1)
        XCTAssertEqual(tree.kind, .directed)
    }

    func test1_8_RandomConnectedGraph() throws {
        let V = 10
        let E = 18
        let graph = try RandomConnectedGraph.build(vertex: V, edge: E)
        XCTAssertEqual(graph.vertexCount, V)
        XCTAssertEqual(graph.edgeCount, E * 2)
        XCTAssertEqual(graph.connectedComponents().count, 1)
    }

    func test1_9_RandomHamiltonGraph() throws {
        let V = 8
        let E = 14
        let graph = try RandomConnectedGraph.hamiltonGraph(vertex: V, edge: E)
        XCTAssertEqual(graph.vertexCount, V)
        XCTAssertEqual(graph.edgeCount, E * 2)
        XCTAssertEqual(graph.connectedComponents().count, 1)
    }

    func test1_10_RandomFlowNetwork() throws {
        let V = 8
        let net = try RandomFlowNetwork.build(vertex: V, layerCount: 3)
        XCTAssertEqual(net.vertexCount, V)
        XCTAssertTrue(net.edgeCount >= V - 1)
        XCTAssertTrue(net.isConnected(from: 0, to: V - 1), "Flow network must connect source 0 to sink \(V-1)")

        // Run max flow on generated network
        let (flow, _) = maxFlow(in: net, from: 0, to: V - 1)
        XCTAssertGreaterThan(flow, 0)
    }

    func test1_11_RandomIsomorphicGraphs() throws {
        let pair = try RandomIsomorphicGraph.build(vertex: 8, edge: 12)
        XCTAssertEqual(pair.original.vertexCount, pair.permuted.vertexCount)
        XCTAssertEqual(pair.original.edgeCount, pair.permuted.edgeCount)

        // Verify the isomorphism mapping preserved all edges
        for edge in pair.original.edges {
            let u_perm = pair.mapping[edge.u]
            let v_perm = pair.mapping[edge.v]
            XCTAssertTrue(pair.permuted.isAdjacent(u: u_perm, v: v_perm),
                          "Isomorphism must preserve edge (\(edge.u), \(edge.v)) -> (\(u_perm), \(v_perm))")
        }
    }

    func test1_12_RandomIsomorphicRegularGraphs() throws {
        let pair = try RandomIsomorphicGraph.regular(vertex: 6, degree: 2)
        XCTAssertEqual(pair.original.vertexCount, 6)
        for v in 0..<6 {
            XCTAssertEqual(pair.original.degree(vertex: v), 2)
            XCTAssertEqual(pair.permuted.degree(vertex: v), 2)
        }
    }
}
