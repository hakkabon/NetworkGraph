import XCTest
@testable import NetworkGraph

final class PropertyMapTests: XCTestCase {

    // MARK: PropertyMap

    func testPropertyMapGetPut() {
        var map = PropertyMap<Int, String>()
        map.put(key: 0, value: "zero")
        map.put(key: 1, value: "one")
        XCTAssertEqual(map.get(key: 0), "zero")
        XCTAssertEqual(map.get(key: 1), "one")
    }

    func testPropertyMapUpdateExistingKey() {
        var map = PropertyMap<String, Int>(dictionary: ["a": 1, "b": 2])
        map.put(key: "a", value: 99)
        XCTAssertEqual(map.get(key: "a"), 99)
    }

    // MARK: VertexAttributes protocols

    func testLabeledVertexConformance() {
        var v = LabeledVertex(label: "Node-1")
        XCTAssertEqual(v.label, "Node-1")
        v.label = "Renamed"
        XCTAssertEqual(v.label, "Renamed")
    }

    func testAnnotatedVertexUserInfo() {
        var v = AnnotatedVertex(label: "A", userInfo: ["color": "red"])
        XCTAssertEqual(v.userInfo["color"], "red")
        v.userInfo["weight"] = "heavy"
        XCTAssertEqual(v.userInfo["weight"], "heavy")
    }

    // MARK: EdgeAttributes protocols

    func testWeightedEdgeConformance() {
        let e = WeightedEdge(weight: 3.5)
        XCTAssertEqual(e.weight, 3.5, accuracy: 1e-9)
        XCTAssertFalse(e.label.isEmpty)
    }

    func testAnnotatedEdgeUserInfo() {
        var e = AnnotatedEdge(label: "Road-42", userInfo: ["type": "highway"])
        XCTAssertEqual(e.userInfo["type"], "highway")
        e.userInfo["lanes"] = "4"
        XCTAssertEqual(e.userInfo["lanes"], "4")
    }

    // MARK: AdjacentGraph with LabeledVertex & WeightedEdge

    func testGraphWithLabeledVerticesAndWeightedEdges() {
        var g = AdjacentGraph<LabeledVertex, WeightedEdge>(
            vertices: [
                LabeledVertex(label: "Paris"),
                LabeledVertex(label: "Lyon"),
                LabeledVertex(label: "Marseille")
            ]
        )
        _ = g.addEdge(u: 0, v: 1)
        _ = g.addEdge(u: 1, v: 2)
        g.setEdgeProperty(WeightedEdge(weight: 465), for: Edge(u: 0, v: 1))
        g.setEdgeProperty(WeightedEdge(weight: 314), for: Edge(u: 1, v: 2))

        XCTAssertEqual(g.edgeProperty(for: Edge(u: 0, v: 1))!.weight, 465, accuracy: 1e-9)
        XCTAssertEqual(g.edgeProperty(for: Edge(u: 1, v: 2))!.weight, 314, accuracy: 1e-9)

        // Update vertex label in-place
        var updated = g.vertexValue(at: 0)
        updated.label = "CDG Airport"
        g.setVertexValue(updated, at: 0)
        XCTAssertEqual(g.vertexValue(at: 0).label, "CDG Airport")
    }
}
