import Foundation
import XCTest
@testable import NetworkGraph

public func readBundle(file: String, ofType type: String, separator: String) throws -> [[String]] {
    var strings : [[String]] = []
    if let filepath: URL = Bundle.module.url(forResource: file, withExtension: type) {
        do {
            let contents = try String(contentsOf: filepath)
            strings.append(contentsOf: contents.components(separatedBy: .newlines)
                            .map { $0.components(separatedBy: separator).filter { !$0.isEmpty } }
                            .filter { $0 != [] }
            )
        }
    }
    return strings
}

final class ImportGraphTests: XCTestCase {
    
    func testImportTiny() throws {
        var graph = AdjacentGraph<Int,NoProperty>()
        let data = try readBundle(file: "tinyDG", ofType: "txt", separator: " ")
        graph.initialize(unweightedGraph: data)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        //print(graph)
    }

    func testImportMedium() throws {
        var graph = AdjacentGraph<Int,NoProperty>()
        let data = try readBundle(file: "mediumDG", ofType: "txt", separator: " ")
        graph.initialize(unweightedGraph: data)
        XCTAssertEqual(graph.kind, GraphType.directed, "expected a directed graph")
        //print(graph)
   }
}
