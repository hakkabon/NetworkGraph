import ArgumentParser
import Foundation
import Files
import NetworkGraph

struct Net: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "net",
        abstract: "NetworkGraph - Combinatorial Optimization & Graph Visualization CLI",
        subcommands: [RandomCmd.self, MstCmd.self, TspCmd.self, FlowCmd.self, ColorCmd.self, MatchCmd.self, PlanarCmd.self]
    )
}

struct RandomCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "random", abstract: "Generate random graphs (Topics 1.1 - 1.12)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 12
    @Option(name: .shortAndLong, help: "Type: general, bipartite, regular, tree, hamilton, flow") var type: String = "general"
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        print("🎲 Generating random '\(type)' graph with \(vertices) vertices...")
        let graph: AdjacentGraph<Int, NoProperty>

        switch type.lowercased() {
        case "bipartite":
            let v1 = vertices / 2
            let v2 = vertices - v1
            graph = try BipartiteRandomGraph.build(partition: v1, partition: v2, edge: Swift.min(edges, v1 * v2))
        case "regular":
            let deg = Swift.min(3, vertices - 1)
            let safeDeg = (vertices * deg) % 2 == 0 ? deg : deg - 1
            graph = try RandomRegularGraph.build(vertex: vertices, degree: Swift.max(2, safeDeg))
        case "tree":
            graph = try RandomTree.labeledTree(vertex: vertices)
        case "hamilton":
            graph = try RandomConnectedGraph.hamiltonGraph(vertex: vertices, edge: Swift.max(vertices, edges))
        default:
            graph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        }

        print(" Graph generated: \(graph.vertexCount) vertices, \(graph.edgeCount) edges")
        if let outPath = output {
            let vGraph = try LayoutBridge.layoutSugiyama(graph: graph, title: "Random \(type.capitalized) Graph")
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print(" Exported visualization to \(outPath)")
        }
    }
}

struct MstCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "mst", abstract: "Compute Minimum Spanning Tree (Topic 2.10)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 14
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let graph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)
        for e in graph.edges {
            let w = Double.random(in: 1.0...10.0).rounded()
            _ = weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = w
        }

        let mst = Connectivity.minimumSpanningTree(graph: weightedGraph)
        print("🌲 Minimum Spanning Tree Total Weight: \(mst.totalWeight)")
        print("   Edges in MST: \(mst.edges)")

        if let outPath = output {
            var edgeLabels: [Edge: String] = [:]
            for e in weightedGraph.edges {
                if let w = weightedGraph.edgeProperties[e] {
                    edgeLabels[e] = "\(Int(w))"
                }
            }
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: weightedGraph,
                title: "Minimum Spanning Tree (Weight: \(mst.totalWeight))",
                highlightEdges: Set(mst.edges),
                edgeLabels: edgeLabels
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print(" Exported visualization to \(outPath)")
        }
    }
}

struct TspCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "tsp", abstract: "Solve Traveling Salesman Problem (Topic 3.12)")

    @Option(name: .shortAndLong, help: "Number of cities") var cities: Int = 6
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        var g = AdjacentGraph<Int, Double>(vertices: Array(0..<cities), kind: .undirected)
        for i in 0..<cities {
            for j in (i + 1)..<cities {
                _ = g.addEdge(u: i, v: j)
                g[Edge(u: i, v: j)] = Double.random(in: 5.0...25.0).rounded()
            }
        }

        let tsp = PathsAndCycles.travelingSalesman(graph: g)
        print(" Optimal TSP Tour: \(tsp.tour)")
        print("💰 Total Travel Cost: \(tsp.totalCost)")

        if let outPath = output {
            let vGraph = LayoutBridge.layoutCircular(
                graph: g,
                title: "Traveling Salesman Tour (Cost: \(tsp.totalCost))",
                tour: tsp.tour
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print(" Exported visualization to \(outPath)")
        }
    }
}

struct FlowCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "flow", abstract: "Solve Max Flow and Min-Cost Flow (Topics 8.1 - 8.2)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 6
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let net = try RandomFlowNetwork.build(vertex: vertices, layerCount: 2)
        let (maxF, solvedNet) = AdvancedFlow.dinicMaxFlow(in: net, from: 0, to: vertices - 1)
        print("🌊 Maximum Network Flow (Dinic): \(maxF)")

        if let outPath = output {
            var labels: [Edge: String] = [:]
            var hlEdges = Set<Edge>()
            for e in solvedNet.edges {
                if let attr = solvedNet.edgeProperties[e] {
                    labels[e] = "\(Int(attr.flow))/\(Int(attr.capacity))"
                    if attr.flow > 0 { hlEdges.insert(e) }
                }
            }

            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: solvedNet,
                title: "Dinic Max Flow: \(maxF)",
                highlightEdges: hlEdges,
                edgeLabels: labels
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print(" Exported visualization to \(outPath)")
        }
    }
}

struct ColorCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "color", abstract: "Vertex Coloring & Chromatic Polynomial (Topics 6.1 - 6.2)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 12
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let graph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        let result = GraphColoring.color(graph)
        print("🎨 Chromatic Number χ(G): \(result.chromaticNumber)")
        print("   Color Classes: \(result.colorClasses)")

        if let outPath = output {
            let theme = GraphVisualTheme.modernDark
            var nodeColors: [Int: String] = [:]
            for (v, c) in result.colors {
                nodeColors[v] = theme.palette[c % theme.palette.count]
            }
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: graph,
                title: "Vertex Coloring (χ = \(result.chromaticNumber))",
                nodeColors: nodeColors
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print(" Exported visualization to \(outPath)")
        }
    }
}

struct MatchCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "match", abstract: "Solve Maximum & Min-Sum Matching (Topics 7.1 - 7.2)")

    @Option(name: .shortAndLong, help: "Partition size") var size: Int = 4
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let graph = try BipartiteRandomGraph.build(partition: size, partition: size, edge: size * 2)
        let matching = GraphMatching.hopcroftKarp(graph: graph, partitionV1: Set(0..<size))
        print("🤝 Maximum Bipartite Matching: \(matching.cardinality) pairs")
        print("   Matched Edges: \(matching.matchedEdges)")

        if let outPath = output {
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: graph,
                title: "Maximum Bipartite Matching (\(matching.cardinality) pairs)",
                highlightEdges: Set(matching.matchedEdges)
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print(" Exported visualization to \(outPath)")
        }
    }
}

struct PlanarCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "planar", abstract: "Test Graph Planarity (Topic 4.1)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 5
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 10

    func run() throws {
        let graph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        let res = Planarity.isPlanar(graph)
        print("🗺️ Is Planar: \(res.isPlanar ? "YES ✅" : "NO ❌")")
    }
}

Net.main()
