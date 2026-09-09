//
//  AdvancedFlowAndPackingCoveringTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class AdvancedFlowAndPackingCoveringTests: XCTestCase {

    // MARK: - Topic 8: Network Flow (Dinic, Push-Relabel, MinCost)

    func test8_1_DinicAndPushRelabel() throws {
        // Build 4-vertex diamond flow network:
        // 0 -> 1 (cap 10), 0 -> 2 (cap 10), 1 -> 3 (cap 10), 2 -> 3 (cap 10), 1 -> 2 (cap 5)
        var net = FlowNetwork(vertices: (0..<4).map { FlowVertex(label: "\($0)") }, kind: .directed)
        _ = try! net.addEdge(u: 0, v: 1); net[Edge(u: 0, v: 1)] = FlowEdge(capacity: 10)
        _ = try! net.addEdge(u: 0, v: 2); net[Edge(u: 0, v: 2)] = FlowEdge(capacity: 10)
        _ = try! net.addEdge(u: 1, v: 3); net[Edge(u: 1, v: 3)] = FlowEdge(capacity: 10)
        _ = try! net.addEdge(u: 2, v: 3); net[Edge(u: 2, v: 3)] = FlowEdge(capacity: 10)
        _ = try! net.addEdge(u: 1, v: 2); net[Edge(u: 1, v: 2)] = FlowEdge(capacity: 5)

        // Dinic max-flow
        let (dinicFlow, _) = AdvancedFlow.dinicMaxFlow(in: net, from: 0, to: 3)
        XCTAssertEqual(dinicFlow, 20.0)

        // Push-Relabel max-flow
        let (prFlow, _) = AdvancedFlow.pushRelabelMaxFlow(in: net, from: 0, to: 3)
        XCTAssertEqual(prFlow, 20.0)
    }

    func test8_2_MinCostMaxFlow() {
        // 0 -> 1 (cap 2, cost 1), 0 -> 2 (cap 1, cost 2), 1 -> 2 (cap 1, cost 1), 1 -> 3 (cap 1, cost 3), 2 -> 3 (cap 2, cost 1)
        var net = FlowNetwork(vertices: (0..<4).map { FlowVertex(label: "\($0)") }, kind: .directed)
        _ = try! net.addEdge(u: 0, v: 1); net[Edge(u: 0, v: 1)] = FlowEdge(capacity: 2, cost: 1)
        _ = try! net.addEdge(u: 0, v: 2); net[Edge(u: 0, v: 2)] = FlowEdge(capacity: 1, cost: 2)
        _ = try! net.addEdge(u: 1, v: 2); net[Edge(u: 1, v: 2)] = FlowEdge(capacity: 1, cost: 1)
        _ = try! net.addEdge(u: 1, v: 3); net[Edge(u: 1, v: 3)] = FlowEdge(capacity: 1, cost: 3)
        _ = try! net.addEdge(u: 2, v: 3); net[Edge(u: 2, v: 3)] = FlowEdge(capacity: 2, cost: 1)

        let result = AdvancedFlow.minCostMaxFlow(in: net, from: 0, to: 3)
        XCTAssertEqual(result.maxFlow, 3.0)
        XCTAssertEqual(result.totalCost, 10.0) // 1 unit along 0->1->3 (4), 1 unit along 0->1->2->3 (3), 1 unit along 0->2->3 (3) = 10
    }

    // MARK: - Topic 9: Packing and Covering

    func test9_1_LinearAssignment() {
        let costs = [
            [4.0, 1.0, 3.0],
            [2.0, 0.0, 5.0],
            [3.0, 2.0, 2.0]
        ]
        let (assign, total) = PackingAndCovering.linearAssignment(costMatrix: costs)
        XCTAssertEqual(assign, [1, 0, 2])
        XCTAssertEqual(total, 5.0) // 0->1 (1) + 1->0 (2) + 2->2 (2) = 5
    }

    func test9_2_BottleneckAssignment() {
        let costs = [
            [1.0, 9.0, 9.0],
            [9.0, 2.0, 9.0],
            [9.0, 9.0, 3.0]
        ]
        let (assign, bottleneck) = PackingAndCovering.bottleneckAssignment(costMatrix: costs)
        XCTAssertEqual(assign, [0, 1, 2])
        XCTAssertEqual(bottleneck, 3.0)
    }

    func test9_3_QuadraticAssignment() {
        // 3 facilities, 3 locations
        let F = [
            [0.0, 5.0, 2.0],
            [5.0, 0.0, 3.0],
            [2.0, 3.0, 0.0]
        ]
        let D = [
            [0.0, 1.0, 2.0],
            [1.0, 0.0, 1.0],
            [2.0, 1.0, 0.0]
        ]
        let qap = PackingAndCovering.quadraticAssignment(flowMatrix: F, distanceMatrix: D)
        XCTAssertEqual(qap.assignment.count, 3)
        XCTAssertGreaterThan(qap.totalCost, 0)
    }

    func test9_4_MultipleKnapsack() {
        let profits = [10.0, 15.0, 20.0, 25.0]
        let weights = [2.0, 3.0, 5.0, 7.0]
        let capacities = [5.0, 7.0]

        let res = PackingAndCovering.multipleKnapsack(profits: profits, weights: weights, capacities: capacities)
        XCTAssertEqual(res.binAssignments.count, 2)
        XCTAssertGreaterThan(res.totalProfit, 0)
    }

    func test9_5_SetCover() {
        // Universe: {0, 1, 2, 3, 4}
        // Subsets: S0={0, 1, 2}, S1={1, 3}, S2={2, 3, 4}, S3={0, 4}
        let subsets = [
            [0, 1, 2],
            [1, 3],
            [2, 3, 4],
            [0, 4]
        ]
        let res = PackingAndCovering.setCover(universeSize: 5, subsets: subsets)
        XCTAssertTrue(res.isComplete)
        XCTAssertTrue(res.selectedSubsets.count >= 2)
    }

    func test9_6_SetPartitioning() {
        // Universe: {0, 1, 2, 3}
        // Subsets: S0={0, 1}, S1={2, 3}, S2={0, 2}, S3={1, 3}
        let subsets = [
            [0, 1],
            [2, 3],
            [0, 2],
            [1, 3]
        ]
        let res = PackingAndCovering.setPartitioning(universeSize: 4, subsets: subsets)
        XCTAssertNotNil(res)
        XCTAssertTrue(res!.isComplete)
        XCTAssertEqual(res!.selectedSubsets.count, 2)
    }
}
