//
//  VisualizationTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class VisualizationTests: XCTestCase {

    func testSugiyamaLayoutAndSVGRendering() throws {
        // Flow Network visualization test
        let net = try RandomFlowNetwork.build(vertex: 6, layerCount: 2)
        let (maxFlow, solvedNet) = AdvancedFlow.dinicMaxFlow(in: net, from: 0, to: 5)
        XCTAssertGreaterThan(maxFlow, 0)

        var labels = [Edge: String]()
        var hlEdges = Set<Edge>()
        for e in solvedNet.edges {
            if let attr = solvedNet.edgeProperties[e] {
                labels[e] = "\(Int(attr.flow))/\(Int(attr.capacity))"
                if attr.flow > 0 { hlEdges.insert(e) }
            }
        }

        let vGraph = try LayoutBridge.layoutSugiyama(
            graph: solvedNet,
            title: "Dinic Max Flow Network",
            highlightEdges: hlEdges,
            edgeLabels: labels
        )

        XCTAssertEqual(vGraph.nodes.count, 6)
        XCTAssertEqual(vGraph.edges.count, solvedNet.edgeCount)

        let svg = SVGGraphRenderer.renderToSVG(vGraph)
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("Dinic Max Flow Network"))
        XCTAssertTrue(svg.contains("</svg>"))
    }

    func testCircularLayoutAndSVGRendering() throws {
        // TSP Tour visualization test
        let cities = 6
        var g = AdjacentGraph<Int, Double>(vertices: Array(0..<cities), kind: .undirected)
        for i in 0..<cities {
            for j in (i + 1)..<cities {
                _ = g.addEdge(u: i, v: j)
                g[Edge(u: i, v: j)] = Double(i + j + 1)
            }
        }

        let tsp = PathsAndCycles.travelingSalesman(graph: g)
        let vGraph = LayoutBridge.layoutCircular(
            graph: g,
            title: "TSP Tour",
            tour: tsp.tour
        )

        XCTAssertEqual(vGraph.nodes.count, cities)
        let svg = SVGGraphRenderer.renderToSVG(vGraph)
        XCTAssertTrue(svg.contains("TSP Tour"))
        XCTAssertTrue(svg.contains("filter=\"url(#glow)\""))
    }

    func testRustLayoutPreservesPinnedRanksAndRoutesByStableID() throws {
        var graph = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .directed)
        _ = graph.addEdge(u: 0, v: 1)
        _ = graph.addEdge(u: 1, v: 2)

        let options = GraphLayoutOptions(
            rankHints: [
                0: GraphRankHint(rank: 0, constraint: .pinned),
                2: GraphRankHint(rank: 2, constraint: .pinned)
            ],
            edgeLabels: [Edge(u: 0, v: 1): "first"]
        )
        let visual = try GraphLayoutEngine().layout(graph, options: options)

        XCTAssertEqual(visual.nodes.first(where: { $0.id == 0 })?.rank, 0)
        XCTAssertEqual(visual.nodes.first(where: { $0.id == 2 })?.rank, 2)
        XCTAssertEqual(visual.edges.map(\.id), [0, 1])
        XCTAssertTrue(visual.edges.allSatisfy { !$0.segments.isEmpty })
        XCTAssertNotNil(visual.edges.first?.labelPosition)
    }

    func testRustLayoutCanonicalizesUndirectedEdges() throws {
        var graph = AdjacentGraph<Int, NoProperty>(vertices: [0, 1], kind: .undirected)
        _ = graph.addEdge(u: 0, v: 1)

        let visual = try GraphLayoutEngine().layout(graph)

        XCTAssertEqual(visual.edges.count, 1)
        XCTAssertFalse(visual.isDirected)
    }

    func testBipartiteValidationRejectsIncompletePartitionsBeforeFFI() throws {
        let graph = AdjacentGraph<Int, NoProperty>(vertices: [0, 1, 2], kind: .undirected)
        let options = GraphLayoutOptions(mode: .bipartite(partitionU: [0], partitionV: [1]))

        XCTAssertThrowsError(try GraphLayoutEngine().layout(graph, options: options)) { error in
            XCTAssertEqual(error as? GraphLayoutError, .incompletePartitions(missing: [2]))
        }
    }

    func testEmptyCircularLayoutDoesNotDivideByZero() {
        let graph = AdjacentGraph<Int, NoProperty>(vertices: [], kind: .undirected)
        let visual = LayoutBridge.layoutCircular(graph: graph, tour: [])
        XCTAssertTrue(visual.nodes.isEmpty)
        XCTAssertTrue(visual.edges.isEmpty)
    }
}
