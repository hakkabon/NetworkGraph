import XCTest
@testable import NetworkGraph

final class ConnectivityTests: XCTestCase {

    // MARK: reachable

    func testReachableLinearChain() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<5))
        for i in 0..<4 { _ = g.addEdge(u: i, v: i+1) }
        let r = g.reachable(from: 0)
        XCTAssertEqual(r, Set(0...4))
    }

    func testReachableIsolatedVertex() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        let r = g.reachable(from: 0)
        XCTAssertFalse(r.contains(2), "vertex 2 is not reachable from 0")
    }

    // MARK: isConnected

    func testIsConnectedYes() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<4))
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        _ = g.addEdge(u: 2, v: 3)
        XCTAssertTrue(g.isConnected(from: 0, to: 3))
    }

    func testIsConnectedNo() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<4))
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 2, v: 3)
        XCTAssertFalse(g.isConnected(from: 0, to: 3))
    }

    // MARK: connectedComponents

    func testConnectedComponentsThreeComponents() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<6))
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 0)   // also test undirected-like bidirectional
        _ = g.addEdge(u: 2, v: 3)
        // 4 and 5 are isolated
        let comps = g.connectedComponents()
        XCTAssertEqual(comps.count, 4, "expected 4 components: {0,1},{2,3},{4},{5}")
    }

    func testConnectedComponentsFullyConnected() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        _ = g.addEdge(u: 0, v: 2)
        let comps = g.connectedComponents()
        XCTAssertEqual(comps.count, 1)
        XCTAssertEqual(comps[0].sorted(), [0, 1, 2])
    }
}
