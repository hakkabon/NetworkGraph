import XCTest
@testable import NetworkGraph

final class BasicVertexTests: XCTestCase {

    // MARK: Read vertex values

    func testReadVertexBySubscript() throws {
        let g = AdjacentGraph<Int, NoProperty>(vertices: [10, 20, 30])
        XCTAssertEqual(g[0], 10)
        XCTAssertEqual(g[1], 20)
        XCTAssertEqual(g[2], 30)
    }

    func testReadVertexByIndex() throws {
        let g = AdjacentGraph<String, NoProperty>(vertices: ["A", "B", "C"])
        XCTAssertEqual(g.vertexValue(at: 0), "A")
        XCTAssertEqual(g.vertexValue(at: 2), "C")
    }

    // MARK: Write vertex values

    func testWriteVertexBySubscript() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        g[1] = 99
        XCTAssertEqual(g[1], 99)
        XCTAssertEqual(g[0], 0, "other vertices should be unchanged")
    }

    func testWriteVertexBySetVertexValue() throws {
        var g = AdjacentGraph<String, NoProperty>(vertices: ["X", "Y", "Z"])
        g.setVertexValue("Alpha", at: 0)
        XCTAssertEqual(g.vertexValue(at: 0), "Alpha")
        XCTAssertEqual(g.vertexValue(at: 1), "Y")
    }

    func testMapVertices() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [1, 2, 3, 4])
        g.mapVertices { $0 * 10 }
        XCTAssertEqual(g.vertices, [10, 20, 30, 40])
    }

    // MARK: Add vertex

    func testAddVertex() throws {
        var g = AdjacentGraph<String, NoProperty>()
        let i = g.addVertex(v: "Node-A")
        let j = g.addVertex(v: "Node-B")
        XCTAssertEqual(g.vertexCount, 2)
        XCTAssertEqual(i, 0)
        XCTAssertEqual(j, 1)
        XCTAssertEqual(g[0], "Node-A")
    }

    // MARK: Remove vertex

    func testRemoveVertexAdjustsCount() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2, 3])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        _ = g.addEdge(u: 2, v: 3)
        g.removeVertex(v: 1)
        XCTAssertEqual(g.vertexCount, 3, "one vertex should be removed")
    }

    func testRemoveVertexRemovesEdges() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        g.removeVertex(v: 1)
        // The old vertex 2 is now at index 1 (re-indexed)
        XCTAssertEqual(g.edgeCount, 0, "edges incident on removed vertex should be gone")
    }

    func testRemoveNonExistentVertexIsNoop() throws {
        var g = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2])
        _ = g.addEdge(u: 0, v: 1)
        g.removeVertex(v: 99)   // 99 is not a vertex value
        XCTAssertEqual(g.vertexCount, 3)
        XCTAssertEqual(g.edgeCount, 1)
    }

    // MARK: Vertex lookup

    func testIndexOfVertex() throws {
        let g = AdjacentGraph<String, NoProperty>(vertices: ["Paris", "London", "Berlin"])
        XCTAssertEqual(g.index(of: "London"), 1)
        XCTAssertNil(g.index(of: "Tokyo"))
    }

    // MARK: VertexAttributes on FlowVertex

    func testFlowVertexAttributes() throws {
        var g = AdjacentGraph<FlowVertex, FlowEdge>(
            vertices: [
                FlowVertex(label: "S", supply: 10),
                FlowVertex(label: "T", supply: -10)
            ]
        )
        XCTAssertEqual(g.vertexAttributes(at: 0).label, "S")
        XCTAssertEqual(g.vertexAttributes(at: 0).supply, 10)

        var updated = g.vertexAttributes(at: 1)
        updated.excess = 5
        g.setVertexAttributes(updated, at: 1)
        XCTAssertEqual(g.vertexAttributes(at: 1).excess, 5)
    }
}
