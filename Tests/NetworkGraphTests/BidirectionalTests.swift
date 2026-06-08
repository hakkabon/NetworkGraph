import XCTest
@testable import NetworkGraph

final class BidirectionalTests: XCTestCase {

    // MARK: indegree

    func testIndegreeDirected() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3])
        _ = g.addEdge(u: 0, v: 3)
        _ = g.addEdge(u: 1, v: 3)
        _ = g.addEdge(u: 2, v: 3)
        _ = g.addEdge(u: 3, v: 0)
        XCTAssertEqual(g.indegree(vertex: 3), 3)
        XCTAssertEqual(g.indegree(vertex: 0), 1)
        XCTAssertEqual(g.indegree(vertex: 1), 0)
    }

    func testIndegreeUndirected() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        XCTAssertEqual(g.indegree(vertex: 1), 2, "undirected: both neighbours count as incoming")
    }

    func testIndegreeSingleVertex() throws {
        let g = AdjacentGraph<Int, NoProperty>(vertices: [42])
        XCTAssertEqual(g.indegree(vertex: 0), 0)
    }

    // MARK: inEdges

    func testInEdges() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3])
        _ = g.addEdge(u: 0, v: 2)
        _ = g.addEdge(u: 1, v: 2)
        let ie = g.inEdges(vertex: 2)
        let sources = Set(ie.map { $0.0 })
        XCTAssertEqual(ie.count, 2)
        XCTAssertTrue(sources.contains(0))
        XCTAssertTrue(sources.contains(1))
    }

    func testInEdgesAfterRemoveEdge() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 2)
        _ = g.addEdge(u: 1, v: 2)
        g.removeEdge(u: 1, v: 2)
        XCTAssertEqual(g.inEdges(vertex: 2).count, 1)
        XCTAssertEqual(g.inEdges(vertex: 2).first?.0, 0)
    }

    // MARK: degree vs indegree

    func testDegreeAndIndegreeSumForDirected() throws {
        // For a directed graph, sum of all outdegrees == sum of all indegrees == |E|
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<5))
        let edgePairs = [(0,1),(0,2),(1,3),(2,3),(3,4)]
        for (u,v) in edgePairs { _ = g.addEdge(u: u, v: v) }

        let totalOut = (0..<5).map { g.degree(vertex: $0) }.reduce(0,+)
        let totalIn  = (0..<5).map { g.indegree(vertex: $0) }.reduce(0,+)
        XCTAssertEqual(totalOut, edgePairs.count)
        XCTAssertEqual(totalIn,  edgePairs.count)
    }
}
