import XCTest
@testable import NetworkGraph

final class NetworkGraphTests: XCTestCase {
    
    func testDepthFirstSearch() throws {
        let edges = [
            (0,3),
            (1,3),
            (1,4),
            (1,5),
            (2,5),
            (2,6),
            (3,10),
            (4,7),
            (4,8),
            (5,8),
            (6,9),
            (6,11),
            (7,10),
            (9,11),
            (9,12),
        ]

        typealias G = AdjacentGraph<Int, NoProperty>
        let graph = G(vertices: Array(0..<13), edges: edges)
        let visitor = AccumulatorVisitor<G.Vertex>()
        var colorMap = PropertyMap<G.Vertex, VertexColor>()
        graph.vertices.forEach { colorMap.put(key: $0, value: VertexColor.white) }
        depthFirstSearch(graph: graph, startVertex: 1, colorMap: &colorMap, visitor: visitor)
        
        print("accumulator: \(visitor.accumulator)")
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        XCTAssertEqual(graph.vertexCount, 13, "expected vertex count = 13")
        XCTAssertEqual(graph.edgeCount, 15, "expected edge count = 15")

        // there are many valid DFS traversals of this graph,
        // but based on the current impl, it will always match the following
        XCTAssertEqual(visitor.accumulator, [10, 3, 7, 8, 4, 5, 1])
    }
    
    func testBreadthFirstSearch() throws {
        let edges = [
            (0,1),
            (1,2),
            (1,3),
            (1,6),
            (2,3),
            (3,4),
            (4,5),
            (5,6),
        ]

        typealias G = AdjacentGraph<Int, NoProperty>
        let graph = G(vertices: Array(0..<7), edges: edges, kind: .undirected)
        let start = graph.index(of: 2)!
        var colorMap = PropertyMap<G.Vertex, VertexColor>()
        let visitor = AccumulatorVisitor<G.Vertex>()
        breadthFirstSearch(graph: graph, startVertex: start, colorMap: &colorMap, visitor: visitor)

        XCTAssertEqual(graph.kind, GraphType.undirected, "expected an undirected graph")
        XCTAssertEqual(graph.vertexCount, 7, "expected vertex count = 7")
        XCTAssertEqual(graph.edgeCount, 16, "expected edge count = 16")

        // there are many valid BFS traversals of this graph starting from vertex 2,
        // but based on the current impl, it will always match the following
        XCTAssertEqual(visitor.accumulator, [2, 1, 3, 0, 6, 4, 5])
    }
}
