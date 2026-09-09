import XCTest
@testable import NetworkGraph

final class InitializeGraphTests: XCTestCase {

    func testOne() throws {
        var graph = AdjacentGraph<Int, NoProperty>(vertices: [0,1,2])
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        XCTAssertEqual(graph.vertexCount, 3, "expected vertex count = 3");
        _ = try! graph.addEdge(u:0, v: 1)
        _ = try! graph.addEdge(u:0, v: 2)
        XCTAssertEqual(graph.edgeCount, 2, "expected edge count = 2");
        let i = graph[1]
        XCTAssertEqual(i, 1, "expected result vetrex[1] = 1");
        graph[1] = 10
        XCTAssertEqual(graph[1], 10, "expected result vetrex[1] = 10");
        _ = try! graph.addEdge(u:1, v: 2)
        XCTAssertEqual(graph.edgeCount, 3, "expected edge count = 3");
    }

    func testTwo() throws {
        var graph = AdjacentGraph<Int, String>(vertices: [0,1,2,3])
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        _ = try! graph.addEdge(u:0, v:1)
        _ = try! graph.addEdge(u:0, v:2)
        _ = try! graph.addEdge(u:1, v:2)
        XCTAssertEqual(graph.vertexCount, 4, "expected vertex count = 4");
        let i = graph[3]
        XCTAssertEqual(i, 3, "expected result vetrex[1] = 3");
        graph[3] = 33
        XCTAssertEqual(graph[3], 33, "expected result vetrex[3] = 33");
        _ = graph[Edge(u:0,v:1)] = "One"
        XCTAssertEqual(graph[Edge(u:0,v:1)], "One", "expected edge value = 'One'");
        _ = graph[Edge(u:0,v:2)] = "Two"
        XCTAssertEqual(graph[Edge(u:0,v:2)], "Two", "expected edge value = 'Two'");
        _ = try! graph.addEdge(u:1, v: 2)
        XCTAssertEqual(graph.edgeCount, 4, "expected edge count = 4");
    }

    func testAdacencyList() throws {
        let adacencyList: [[Int]] = [
            [1, 6, 8],
            [0, 4, 6, 9],
            [4, 6],
            [4, 5, 8],
            [1, 2, 3, 5, 9],
            [3, 4],
            [0, 1, 2],
            [8, 9],
            [0, 3, 7],
            [1, 4, 7]
        ]
        let graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0...9), adacency: adacencyList)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        XCTAssertEqual(graph.vertex, [0,1,2,3,4,5,6,7,8,9], "expected vertex values [0,1,2,3,4,5,6,7,8,9]")
        XCTAssertEqual(graph.edgeCount, 30, "expected egde count = 30")
        XCTAssertEqual(graph.vertexCount, adacencyList.count, "expected vertex count = 10")
    }
    
    func testEdgeList() throws {
        let edges: [(Int,Int)] = [
            (0,1),(0,6),(0,8),                  // [1, 6, 8],
            (1,0),(1,4),(1,6),(1,9),            // [0, 4, 6, 9],
            (2,4),(2,6),                        // [4, 6],
            (3,4),(3,5),(3,8),                  // [4, 5, 8],
            (4,1),(4,2),(4,3),(4,5),(4,9),      // [1, 2, 3, 5, 9],
            (5,3),(5,4),                        // [3, 4],
            (5,0),(5,1),(5,2),                  // [0, 1, 2],
            (6,8),(6,9),                        // [8, 9],
            (7,0),(7,3),(7,7),                  // [0, 3, 7],
            (8,1),(8,4),(8,7),                  // [1, 4, 7]
        ]
        let graph = AdjacentGraph<Int, NoProperty>(vertices: Array(0...9), edges: edges)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        XCTAssertEqual(graph.vertex, [0,1,2,3,4,5,6,7,8,9], "expected vertex values [0,1,2,3,4,5,6,7,8,9]")
        XCTAssertEqual(graph.edgeCount, 30, "expected egde count = 30")
        XCTAssertEqual(graph.vertexCount, 10, "expected vertex count = 10")
    }
    
    func testInitializeSymbolGraph() throws {
        let data: [(String,String)] = try readBundle(file: "routes", ofType: "txt", separator: " ").map { $0.splat2() }
        let graph = AdjacentGraph<String,NoProperty>(data)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        //print(graph)
    }

    func testInitializeWeightedSymbolGraph() throws {
        let data: [(String,String,String)] = try readBundle(file: "routes-weighted", ofType: "txt", separator: " ").map { $0.splat3() }
        let graph = AdjacentGraph<String,Double>(data)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        //print(graph)
    }
    
    func testWeightedSymbolGraph() throws {
        let data: [(String,String,String)] = try readBundle(file: "usa-map", ofType: "csv", separator: ",").map { $0.splat3() }
        let graph = AdjacentGraph<String,Int>(data)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        //print(graph)
   }
}
