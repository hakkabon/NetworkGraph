import Foundation
import XCTest
@testable import NetworkGraph

final class TopologicalTests: XCTestCase {

    func testTopologicalSort() throws {
        let edges = [
            (0,3),(1,3),(1,4),(1,5),(2,5),(2,6),
            (3,10),(4,7),(4,8),(5,8),(6,9),(6,11),
            (7,10),(9,11),(9,12),
        ]
        let graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0...12), edges: edges)
        XCTAssertEqual(graph.kind, .directed)
        XCTAssertEqual(graph.vertexCount, 13)
        XCTAssertEqual(graph.edgeCount, 15)

        let topology = topologicalSort(graph: graph)
        // Verify that every edge (u,v) has u appearing after v in the result
        // (post-order DFS reversal = topological order where u comes after its descendants)
        let pos = Dictionary(uniqueKeysWithValues: topology.enumerated().map { ($1, $0) })
        for (u, v) in edges {
            XCTAssertLessThan(pos[v]!, pos[u]!,
                              "topological violation: \(u) must appear before \(v) is finished")
        }
        // Deterministic result for this specific graph / DFS implementation
        XCTAssertEqual(topology, [10, 3, 0, 8, 5, 11, 12, 9, 6, 2, 7, 4, 1])
    }

    func testTopologicalSortLinearChain() throws {
        // 0 → 1 → 2 → 3: topological order must be [3,2,1,0]
        let graph = AdjacentGraph<Int, NoProperty>(
            vertices: [0,1,2,3],
            edges: [(0,1),(1,2),(2,3)])
        let topology = topologicalSort(graph: graph)
        XCTAssertEqual(topology, [3, 2, 1, 0])
    }

    func testTopologicalSortSingleVertex() throws {
        let graph = AdjacentGraph<Int, NoProperty>(vertices: [0])
        let topology = topologicalSort(graph: graph)
        XCTAssertEqual(topology, [0])
    }
}
