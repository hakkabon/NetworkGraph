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

    func testEdgeCostsAndTourBadgesRenderedInSVG() throws {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = g.addEdge(u: 0, v: 1); g[Edge(u: 0, v: 1)] = 5.0
        _ = g.addEdge(u: 1, v: 2); g[Edge(u: 1, v: 2)] = 12.0
        _ = g.addEdge(u: 2, v: 3); g[Edge(u: 2, v: 3)] = 7.0
        _ = g.addEdge(u: 3, v: 0); g[Edge(u: 3, v: 0)] = 9.0

        let vGraph = LayoutBridge.layoutCircular(
            graph: g,
            title: "Tour With Costs",
            tour: [0, 1, 2, 3, 0],
            cutNodes: [1]
        )

        XCTAssertEqual(vGraph.badges.count, 4)
        XCTAssertEqual(vGraph.edges.count, 4)
        XCTAssertTrue(vGraph.edges.allSatisfy { $0.label != nil })

        // Verify that on each edge, the badge and the edge label are separated by at least 20px
        for (i, edge) in vGraph.edges.enumerated() {
            guard let labelPos = edge.labelPosition, i < vGraph.badges.count else { continue }
            let badgePos = vGraph.badges[i].position
            let dx = labelPos.x - badgePos.x
            let dy = labelPos.y - badgePos.y
            let dist = sqrt(dx * dx + dy * dy)
            XCTAssertGreaterThan(dist, 30.0, "Tour badge and edge cost label should not collide")
        }

        let svg = SVGGraphRenderer.renderToSVG(vGraph)
        XCTAssertTrue(svg.contains("Tour With Costs"))
        XCTAssertTrue(svg.contains("class=\"tour-badge\""))
        XCTAssertTrue(svg.contains("class=\"edge-label\""))
        XCTAssertTrue(svg.contains("5"))
        XCTAssertTrue(svg.contains("12"))
        XCTAssertTrue(svg.contains("filter=\"url(#cutGlow)\""))
    }

    func testHullsAndPartitionsRenderedInSVG() throws {
        var g = AdjacentGraph<Int, Double>(vertices: [0, 1, 2, 3], kind: .undirected)
        _ = g.addEdge(u: 0, v: 2); g[Edge(u: 0, v: 2)] = 10.0
        _ = g.addEdge(u: 1, v: 3); g[Edge(u: 1, v: 3)] = 15.0

        let vBipartite = try LayoutBridge.layoutBipartite(
            graph: g,
            partitionU: [0, 1],
            partitionV: [2, 3],
            labelU: "Left Side",
            labelV: "Right Side",
            matchedEdges: [Edge(u: 0, v: 2), Edge(u: 1, v: 3)]
        )

        let svgBipartite = SVGGraphRenderer.renderToSVG(vBipartite)
        XCTAssertTrue(svgBipartite.contains("class=\"partition-lane\""))
        XCTAssertTrue(svgBipartite.contains("Left Side"))
        XCTAssertTrue(svgBipartite.contains("Right Side"))
        XCTAssertTrue(svgBipartite.contains("10"))
        XCTAssertTrue(svgBipartite.contains("15"))

        let vComponents = try LayoutBridge.layoutComponents(
            graph: g,
            componentGroups: [[0, 2], [1, 3]],
            hullLabels: ["Component A", "Component B"]
        )
        let svgComponents = SVGGraphRenderer.renderToSVG(vComponents)
        XCTAssertTrue(svgComponents.contains("class=\"hull\""))
        XCTAssertTrue(svgComponents.contains("Component A"))
        XCTAssertTrue(svgComponents.contains("Component B"))
    }
}
