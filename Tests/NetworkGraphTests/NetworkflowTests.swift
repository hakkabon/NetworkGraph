import XCTest
@testable import NetworkGraph

// MARK: - Helpers

private func makeSimpleNetwork() -> FlowNetwork {
    // Classic 4-node flow network:
    //
    //   S --10--> A --10--> T
    //   S -- 5--> B -- 5--> T
    //   A -- 3--> B
    //
    // Max flow S→T = 15
    var g = FlowNetwork(vertices: [
        FlowVertex(label: "S"),
        FlowVertex(label: "A"),
        FlowVertex(label: "B"),
        FlowVertex(label: "T")
    ])
    _ = g.addEdge(u: 0, v: 1)   // S→A
    _ = g.addEdge(u: 0, v: 2)   // S→B
    _ = g.addEdge(u: 1, v: 3)   // A→T
    _ = g.addEdge(u: 2, v: 3)   // B→T
    _ = g.addEdge(u: 1, v: 2)   // A→B
    g.setEdgeAttributes(FlowEdge(capacity: 10), for: Edge(u: 0, v: 1))
    g.setEdgeAttributes(FlowEdge(capacity: 5),  for: Edge(u: 0, v: 2))
    g.setEdgeAttributes(FlowEdge(capacity: 10), for: Edge(u: 1, v: 3))
    g.setEdgeAttributes(FlowEdge(capacity: 5),  for: Edge(u: 2, v: 3))
    g.setEdgeAttributes(FlowEdge(capacity: 3),  for: Edge(u: 1, v: 2))
    return g
}

// MARK: - FlowVertex tests

final class FlowVertexTests: XCTestCase {

    func testFlowVertexDefaultValues() {
        let v = FlowVertex(label: "X")
        XCTAssertEqual(v.label, "X")
        XCTAssertEqual(v.excess, 0)
        XCTAssertEqual(v.height, 0)
        XCTAssertEqual(v.supply, 0)
    }

    func testFlowVertexMutation() {
        var v = FlowVertex(label: "Node", excess: 0, height: 0, supply: 10)
        v.excess = 7
        v.height = 2
        XCTAssertEqual(v.excess, 7)
        XCTAssertEqual(v.height, 2)
        XCTAssertEqual(v.supply, 10)
    }

    func testSetVertexAttributesOnGraph() {
        var g = FlowNetwork(vertices: [FlowVertex(label: "S"), FlowVertex(label: "T")])
        var attr = g.vertexAttributes(at: 0)
        attr.supply = 20
        g.setVertexAttributes(attr, at: 0)
        XCTAssertEqual(g.vertexAttributes(at: 0).supply, 20)
    }
}

// MARK: - FlowEdge tests

final class FlowEdgeTests: XCTestCase {

    func testFlowEdgeResidualCapacity() {
        let e = FlowEdge(capacity: 10, flow: 4)
        XCTAssertEqual(e.residualCapacity, 6, accuracy: 1e-9)
    }

    func testFlowEdgeIsSaturated() {
        let sat = FlowEdge(capacity: 5, flow: 5)
        let notSat = FlowEdge(capacity: 5, flow: 3)
        XCTAssertTrue(sat.isSaturated)
        XCTAssertFalse(notSat.isSaturated)
    }

    func testFlowEdgeFlowClampedToCapacity() {
        // flow > capacity should be clamped
        var e = FlowEdge(capacity: 5)
        e.flow = 100
        XCTAssertEqual(e.flow, 5, "flow must not exceed capacity")
    }

    func testFlowEdgeFlowClampedToLowerBound() {
        var e = FlowEdge(capacity: 10, lowerBound: 2)
        e.flow = -5
        XCTAssertEqual(e.flow, 2, "flow must not go below lowerBound")
    }

    func testSetEdgeAttributesOnGraph() {
        var g = FlowNetwork(vertices: [FlowVertex(label: "A"), FlowVertex(label: "B")])
        _ = g.addEdge(u: 0, v: 1)
        g.setEdgeAttributes(FlowEdge(capacity: 8, cost: 2), for: Edge(u: 0, v: 1))
        let attr = g.edgeAttributes(for: Edge(u: 0, v: 1))!
        XCTAssertEqual(attr.capacity, 8)
        XCTAssertEqual(attr.cost, 2)
    }
}

// MARK: - Max-flow tests

final class MaxFlowTests: XCTestCase {

    func testMaxFlowSimpleNetwork() {
        let net = makeSimpleNetwork()
        let (flow, _) = maxFlow(in: net, from: 0, to: 3)
        // S has capacity 10+5 = 15 outgoing; T has capacity 10+5 = 15 incoming
        XCTAssertEqual(flow, 15, accuracy: 1e-9)
    }

    func testMaxFlowLinearChain() {
        // S --5--> A --3--> T   bottleneck is 3
        var g = FlowNetwork(vertices: [FlowVertex(label: "S"),
                                       FlowVertex(label: "A"),
                                       FlowVertex(label: "T")])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        g.setEdgeAttributes(FlowEdge(capacity: 5), for: Edge(u: 0, v: 1))
        g.setEdgeAttributes(FlowEdge(capacity: 3), for: Edge(u: 1, v: 2))
        let (flow, _) = maxFlow(in: g, from: 0, to: 2)
        XCTAssertEqual(flow, 3, accuracy: 1e-9)
    }

    func testMaxFlowDisconnected() {
        var g = FlowNetwork(vertices: [FlowVertex(label: "S"),
                                       FlowVertex(label: "T")])
        // No edge between S and T
        let (flow, _) = maxFlow(in: g, from: 0, to: 1)
        XCTAssertEqual(flow, 0, accuracy: 1e-9)
    }

    func testMaxFlowSingleEdge() {
        var g = FlowNetwork(vertices: [FlowVertex(label: "S"), FlowVertex(label: "T")])
        _ = g.addEdge(u: 0, v: 1)
        g.setEdgeAttributes(FlowEdge(capacity: 7), for: Edge(u: 0, v: 1))
        let (flow, _) = maxFlow(in: g, from: 0, to: 1)
        XCTAssertEqual(flow, 7, accuracy: 1e-9)
    }

    func testMaxFlowNetworkFlowConservation() {
        // After running max-flow, verify flow conservation:
        // for every non-source/sink vertex: inflow == outflow
        let net = makeSimpleNetwork()
        let (_, result) = maxFlow(in: net, from: 0, to: 3)

        for v in 1..<3 {   // A and B
            let inflow  = result.inEdges(vertex: v)
                .compactMap { result.edgeProperty(for: Edge(u: $0.0, v: $0.1)) }
                .reduce(0.0) { $0 + $1.flow }
            let outflow = result.adjacentEdges(of: v)
                .compactMap { result.edgeProperty(for: Edge(u: $0.0, v: $0.1)) }
                .reduce(0.0) { $0 + $1.flow }
            XCTAssertEqual(inflow, outflow, accuracy: 1e-9, "flow conservation violated at vertex \(v)")
        }
    }

    func testMaxFlowReturnsNewNetwork() {
        // The original graph must be immutable (Ford-Fulkerson operates on a copy)
        let net = makeSimpleNetwork()
        let (_, result) = maxFlow(in: net, from: 0, to: 3)
        // source network edges should still have flow == 0
        let originalFlow = net.edgeProperty(for: Edge(u: 0, v: 1))?.flow ?? -1
        XCTAssertEqual(originalFlow, 0, accuracy: 1e-9, "original network should not be modified")
        _ = result  // result has non-zero flows
    }
}

// MARK: - NetworkFlowGraph protocol conformance tests

final class NetworkFlowGraphProtocolTests: XCTestCase {

    func testDefaultSourceAndSink() {
        let g = FlowNetwork(vertices: [
            FlowVertex(label: "S"),
            FlowVertex(label: "M"),
            FlowVertex(label: "T")
        ])
        XCTAssertEqual(g.source, 0)
        XCTAssertEqual(g.sink, 2)
    }

    func testEmptyFlowNetwork() {
        let g = FlowNetwork()
        XCTAssertEqual(g.vertexCount, 0)
        XCTAssertEqual(g.edgeCount, 0)
    }

    func testBuildFlowNetworkIncrementally() {
        var g = FlowNetwork()
        let s = g.addVertex(v: FlowVertex(label: "source"))
        let m = g.addVertex(v: FlowVertex(label: "mid"))
        let t = g.addVertex(v: FlowVertex(label: "sink"))
        _ = g.addEdge(u: s, v: m)
        _ = g.addEdge(u: m, v: t)
        g.setEdgeAttributes(FlowEdge(capacity: 5), for: Edge(u: s, v: m))
        g.setEdgeAttributes(FlowEdge(capacity: 5), for: Edge(u: m, v: t))
        XCTAssertEqual(g.vertexCount, 3)
        XCTAssertEqual(g.edgeCount, 2)
        let (flow, _) = maxFlow(in: g, from: s, to: t)
        XCTAssertEqual(flow, 5, accuracy: 1e-9)
    }
}
