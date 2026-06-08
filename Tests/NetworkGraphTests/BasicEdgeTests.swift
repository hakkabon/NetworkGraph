import XCTest
@testable import NetworkGraph

final class BasicEdgeTests: XCTestCase {

    // MARK: Read edge properties

    func testReadEdgePropertyBySubscript() throws {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        g[Edge(u: 0, v: 1)] = 3.14
        XCTAssertEqual(g[Edge(u: 0, v: 1)], 3.14, accuracy: 1e-9)
    }

    func testReadEdgePropertySafeSubscript() throws {
        var g = AdjacentGraph<Int, String>(vertices: [0, 1])
        _ = g.addEdge(u: 0, v: 1)
        XCTAssertNil(g[safe: Edge(u: 0, v: 1)], "no property stored yet")
        g[safe: Edge(u: 0, v: 1)] = "hello"
        XCTAssertEqual(g[safe: Edge(u: 0, v: 1)], "hello")
    }

    func testReadEdgePropertyByAPI() throws {
        var g = AdjacentGraph<Int, Int>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 1, v: 2)
        g.setEdgeProperty(42, for: Edge(u: 1, v: 2))
        XCTAssertEqual(g.edgeProperty(for: Edge(u: 1, v: 2)), 42)
        XCTAssertNil(g.edgeProperty(for: Edge(u: 0, v: 1)))
    }

    // MARK: Write edge properties

    func testWriteEdgePropertyBySubscript() throws {
        var g = AdjacentGraph<Int, String>(vertices: [0, 1])
        _ = g.addEdge(u: 0, v: 1)
        g[Edge(u: 0, v: 1)] = "first"
        XCTAssertEqual(g[Edge(u: 0, v: 1)], "first")
        g[Edge(u: 0, v: 1)] = "updated"
        XCTAssertEqual(g[Edge(u: 0, v: 1)], "updated")
    }

    func testWriteEdgePropertyBySetEdgeProperty() throws {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3])
        _ = g.addEdge(u: 0, v: 3)
        g.setEdgeProperty(99.9, for: Edge(u: 0, v: 3))
        XCTAssertEqual(g.edgeProperty(for: Edge(u: 0, v: 3))!, 99.9, accuracy: 1e-9)
    }

    func testMapEdges() throws {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        g.setEdgeProperty(1.0, for: Edge(u: 0, v: 1))
        g.setEdgeProperty(2.0, for: Edge(u: 1, v: 2))
        g.mapEdges { $0 * 10 }
        XCTAssertEqual(g.edgeProperty(for: Edge(u: 0, v: 1))!, 10.0, accuracy: 1e-9)
        XCTAssertEqual(g.edgeProperty(for: Edge(u: 1, v: 2))!, 20.0, accuracy: 1e-9)
    }

    // MARK: Add / remove edges

    func testAddEdge() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        XCTAssertTrue(g.addEdge(u: 0, v: 1))
        XCTAssertTrue(g.addEdge(u: 1, v: 2))
        XCTAssertEqual(g.edgeCount, 2)
        XCTAssertTrue(g.isAdjacent(u: 0, v: 1))
        XCTAssertTrue(g.isAdjacent(u: 1, v: 2))
        XCTAssertFalse(g.isAdjacent(u: 0, v: 2))
    }

    func testAddEdgeUndirected() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = g.addEdge(u: 0, v: 1)
        XCTAssertTrue(g.isAdjacent(u: 0, v: 1))
        XCTAssertTrue(g.isAdjacent(u: 1, v: 0), "undirected edge must be symmetric")
    }

    func testRemoveEdge() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        g.removeEdge(u: 0, v: 1)
        XCTAssertEqual(g.edgeCount, 1)
        XCTAssertFalse(g.isAdjacent(u: 0, v: 1))
        XCTAssertTrue(g.isAdjacent(u: 1, v: 2))
    }

    func testRemoveEdgeClearsProperty() throws {
        var g = AdjacentGraph<Int, String>(vertices: [0, 1])
        _ = g.addEdge(u: 0, v: 1)
        g.setEdgeProperty("label", for: Edge(u: 0, v: 1))
        g.removeEdge(u: 0, v: 1)
        XCTAssertNil(g.edgeProperty(for: Edge(u: 0, v: 1)), "property should be removed with edge")
    }

    func testRemoveAllAdjacentEdges() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3])
        _ = g.addEdge(u: 1, v: 0)
        _ = g.addEdge(u: 1, v: 2)
        _ = g.addEdge(u: 1, v: 3)
        _ = g.addEdge(u: 0, v: 2)
        g.removeAllAdjacentEdges(of: 1)
        XCTAssertEqual(g.degree(vertex: 1), 0)
        XCTAssertEqual(g.edgeCount, 1, "only the 0→2 edge should remain")
    }

    // MARK: edges computed property

    func testEdgesListDirected() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 0, v: 2)
        _ = g.addEdge(u: 1, v: 2)
        let edgeSet = Set(g.edges)
        XCTAssertTrue(edgeSet.contains(Edge(u: 0, v: 1)))
        XCTAssertTrue(edgeSet.contains(Edge(u: 0, v: 2)))
        XCTAssertTrue(edgeSet.contains(Edge(u: 1, v: 2)))
        XCTAssertEqual(g.edges.count, 3)
    }

    // MARK: FlowEdge attributes

    func testFlowEdgeReadWrite() throws {
        var g = FlowNetwork(vertices: [
            FlowVertex(label: "S"),
            FlowVertex(label: "T")
        ])
        _ = g.addEdge(u: 0, v: 1)
        g.setEdgeAttributes(FlowEdge(capacity: 10, flow: 3), for: Edge(u: 0, v: 1))

        let attr = g.edgeAttributes(for: Edge(u: 0, v: 1))!
        XCTAssertEqual(attr.capacity, 10)
        XCTAssertEqual(attr.flow, 3)
        XCTAssertEqual(attr.residualCapacity, 7, accuracy: 1e-9)
        XCTAssertFalse(attr.isSaturated)
    }

    func testFlowEdgeSaturation() throws {
        var g = FlowNetwork(vertices: [FlowVertex(label: "A"), FlowVertex(label: "B")])
        _ = g.addEdge(u: 0, v: 1)
        g.setEdgeAttributes(FlowEdge(capacity: 5, flow: 5), for: Edge(u: 0, v: 1))
        XCTAssertTrue(g.edgeAttributes(for: Edge(u: 0, v: 1))!.isSaturated)
    }

    // MARK: Edge struct

    func testEdgeReversed() throws {
        let e = Edge(u: 3, v: 7)
        let r = e.reversed()
        XCTAssertEqual(r.u, 7)
        XCTAssertEqual(r.v, 3)
    }

    func testEdgeEquality() throws {
        XCTAssertEqual(Edge(u: 1, v: 2), Edge(u: 1, v: 2))
        XCTAssertNotEqual(Edge(u: 1, v: 2), Edge(u: 2, v: 1))
    }

    func testEdgeHashable() throws {
        var s = Set<Edge>()
        s.insert(Edge(u: 0, v: 1))
        s.insert(Edge(u: 0, v: 1))
        s.insert(Edge(u: 1, v: 0))
        XCTAssertEqual(s.count, 2)
    }
}
