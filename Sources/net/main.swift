import ArgumentParser
import Foundation
import Files
import NetworkGraph

struct Net: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "net",
        abstract: "NetworkGraph - Combinatorial Optimization & Graph Visualization CLI",
        subcommands: [
            RandomCmd.self,
            MstCmd.self,
            TspCmd.self,
            EulerCmd.self,
            PostmanCmd.self,
            ShortestPathCmd.self,
            FlowCmd.self,
            ColorCmd.self,
            MatchCmd.self,
            PlanarCmd.self
        ]
    )
}

// MARK: - 1. Random Graph Command

struct RandomCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "random", abstract: "Generate random graphs with edge costs (Topics 1.1 - 1.12)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 12
    @Option(name: .shortAndLong, help: "Type: general, bipartite, regular, tree, hamilton, flow") var type: String = "general"
    @Flag(name: .shortAndLong, help: "Assign random costs/weights to edges") var weighted: Bool = true
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        print("🎲 Generating random '\(type)' graph with \(vertices) vertices...")
        var graph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)

        switch type.lowercased() {
        case "bipartite":
            let v1 = vertices / 2
            let v2 = vertices - v1
            let unweighted = try BipartiteRandomGraph.build(partition: v1, partition: v2, edge: Swift.min(edges, v1 * v2))
            for e in unweighted.edges {
                _ = try graph.addEdge(u: e.u, v: e.v)
                graph[e] = Double.random(in: 1.0...20.0).rounded()
            }
        case "regular":
            let deg = Swift.min(3, vertices - 1)
            let safeDeg = (vertices * deg) % 2 == 0 ? deg : deg - 1
            let unweighted = try RandomRegularGraph.build(vertex: vertices, degree: Swift.max(2, safeDeg))
            for e in unweighted.edges {
                _ = try graph.addEdge(u: e.u, v: e.v)
                graph[e] = Double.random(in: 1.0...20.0).rounded()
            }
        case "tree":
            let unweighted = try RandomTree.labeledTree(vertex: vertices)
            for e in unweighted.edges {
                _ = try graph.addEdge(u: e.u, v: e.v)
                graph[e] = Double.random(in: 1.0...20.0).rounded()
            }
        case "hamilton":
            let unweighted = try RandomConnectedGraph.hamiltonGraph(vertex: vertices, edge: Swift.max(vertices, edges))
            for e in unweighted.edges {
                _ = try graph.addEdge(u: e.u, v: e.v)
                graph[e] = Double.random(in: 1.0...20.0).rounded()
            }
        default:
            let unweighted = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
            for e in unweighted.edges {
                _ = try graph.addEdge(u: e.u, v: e.v)
                graph[e] = Double.random(in: 1.0...20.0).rounded()
            }
        }

        print("✅ Graph generated: \(graph.vertexCount) vertices, \(graph.edgeCount) edges")
        if let outPath = output {
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: graph,
                title: "Random \(type.capitalized) Graph (\(graph.vertexCount)V, \(graph.edgeCount)E)"
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported visualization with edge costs to \(outPath)")
        }
    }
}

// MARK: - Graphviz Helper

private func emitGraphviz(dot: String, to path: String) throws {
    let dotPath = path.hasSuffix(".dot") ? path : path + ".dot"
    try dot.write(toFile: dotPath, atomically: true, encoding: .utf8)
    print("📐 DOT source written to \(dotPath)")
    do {
        try GraphvizExporter.render(dot: dot, to: path, open: true)
        print("🖼️ Graphviz render opened: \(path)")
    } catch GraphvizExporterError.dotNotFound {
        print("⚠️  \(GraphvizExporterError.dotNotFound.localizedDescription)")
    }
}

// MARK: - 2. Minimum Spanning Tree Command

struct MstCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "mst", abstract: "Compute Minimum Spanning Tree (Topic 2.10)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 14
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?
    @Option(name: .long, help: "Output Graphviz DOT/PDF file (requires 'dot' from graphviz)") var graphviz: String?

    func run() throws {
        let baseGraph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)
        for e in baseGraph.edges {
            let w = Double.random(in: 1.0...15.0).rounded()
            _ = try weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = w
        }

        let mst = Connectivity.minimumSpanningTree(graph: weightedGraph)
        print("🌲 Minimum Spanning Tree Total Weight: \(mst.totalWeight)")
        print("   Edges in MST: \(mst.edges)")

        if let outPath = output {
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: weightedGraph,
                title: "Minimum Spanning Tree (Weight: \(mst.totalWeight))",
                highlightEdges: Set(mst.edges)
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported visualization with edge costs to \(outPath)")
        }

        if let gvPath = graphviz {
            let dot = GraphvizExporter.dot(
                graph: weightedGraph,
                title: "MST (Weight: \(mst.totalWeight))",
                highlightEdges: Set(mst.edges)
            )
            try emitGraphviz(dot: dot, to: gvPath)
        }
    }
}

// MARK: - 3. Traveling Salesman Problem Command

struct TspCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "tsp", abstract: "Solve Traveling Salesman Problem (Topic 3.12)")

    @Option(name: .shortAndLong, help: "Number of cities") var cities: Int = 6
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?
    @Option(name: .long, help: "Output Graphviz DOT/PDF file (requires 'dot' from graphviz)") var graphviz: String?

    func run() throws {
        var g = AdjacentGraph<Int, Double>(vertices: Array(0..<cities), kind: .undirected)
        for i in 0..<cities {
            for j in (i + 1)..<cities {
                _ = try g.addEdge(u: i, v: j)
                g[Edge(u: i, v: j)] = Double.random(in: 5.0...30.0).rounded()
            }
        }

        let tsp = PathsAndCycles.travelingSalesman(graph: g)
        print("🚀 Optimal TSP Tour: \(tsp.tour)")
        print("💰 Total Travel Cost: \(tsp.totalCost)")

        if let outPath = output {
            let vGraph = LayoutBridge.layoutCircular(
                graph: g,
                title: "Traveling Salesman Tour (Cost: \(tsp.totalCost))",
                tour: tsp.tour
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported visualization with tour step badges & edge costs to \(outPath)")
        }

        if let gvPath = graphviz {
            let dot = GraphvizExporter.dot(
                graph: g,
                title: "TSP Tour (Cost: \(tsp.totalCost))",
                tour: tsp.tour
            )
            try emitGraphviz(dot: dot, to: gvPath)
        }
    }
}

// MARK: - 4. Euler Circuit / Trail Command

struct EulerCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "euler", abstract: "Compute Eulerian Circuit or Trail (Topic 3.9)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 6
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?
    @Option(name: .long, help: "Output Graphviz DOT/PDF file (requires 'dot' from graphviz)") var graphviz: String?

    func run() throws {
        // Construct an Eulerian graph (e.g. 2-regular or random regular)
        let baseGraph = try RandomRegularGraph.build(vertex: vertices, degree: 4)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)
        for e in baseGraph.edges {
            _ = try weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = Double.random(in: 1.0...10.0).rounded()
        }

        guard let euler = PathsAndCycles.eulerCircuit(weightedGraph) else {
            print("❌ Graph has no Eulerian circuit.")
            return
        }

        print("🔄 Euler \(euler.isCircuit ? "Circuit" : "Trail"): \(euler.vertices)")
        print("   Edges Traversed: \(euler.edges.count)")

        if let outPath = output {
            let vGraph = LayoutBridge.layoutCircular(
                graph: weightedGraph,
                title: "Eulerian \(euler.isCircuit ? "Circuit" : "Trail") (\(euler.edges.count) steps)",
                tour: euler.vertices
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported Eulerian tour visualization to \(outPath)")
        }

        if let gvPath = graphviz {
            let dot = GraphvizExporter.dot(
                graph: weightedGraph,
                title: "Eulerian \(euler.isCircuit ? "Circuit" : "Trail")",
                tour: euler.vertices
            )
            try emitGraphviz(dot: dot, to: gvPath)
        }
    }
}

// MARK: - 5. Chinese Postman Command

struct PostmanCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "postman", abstract: "Solve Chinese Postman Problem (Topic 3.11)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 6
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 9
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?
    @Option(name: .long, help: "Output Graphviz DOT/PDF file (requires 'dot' from graphviz)") var graphviz: String?

    func run() throws {
        let baseGraph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)
        for e in baseGraph.edges {
            _ = try weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = Double.random(in: 2.0...15.0).rounded()
        }

        guard let postman = PathsAndCycles.chinesePostmanTour(graph: weightedGraph) else {
            print("❌ Could not compute Chinese Postman tour.")
            return
        }

        var totalCost = 0.0
        for i in 0..<(postman.vertices.count - 1) {
            let u = postman.vertices[i]
            let v = postman.vertices[i + 1]
            totalCost += weightedGraph.edgeProperties[Edge(u: u, v: v)] ?? weightedGraph.edgeProperties[Edge(u: v, v: u)] ?? 0.0
        }

        print("📬 Chinese Postman Tour: \(postman.vertices)")
        print("💰 Total Route Cost: \(totalCost)")

        if let outPath = output {
            let vGraph = LayoutBridge.layoutCircular(
                graph: weightedGraph,
                title: "Chinese Postman Tour (Cost: \(totalCost))",
                tour: postman.vertices
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported Chinese Postman visualization to \(outPath)")
        }

        if let gvPath = graphviz {
            let dot = GraphvizExporter.dot(
                graph: weightedGraph,
                title: "Chinese Postman Tour (Cost: \(totalCost))",
                tour: postman.vertices
            )
            try emitGraphviz(dot: dot, to: gvPath)
        }
    }
}

// MARK: - 6. Shortest Path Command

struct ShortestPathCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "sp", abstract: "Compute Shortest Path via Bidirectional Dijkstra (Topic 3.3)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 14
    @Option(name: .shortAndLong, help: "Source vertex") var source: Int = 0
    @Option(name: .shortAndLong, help: "Target vertex") var target: Int = 7
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?
    @Option(name: .long, help: "Output Graphviz DOT/PDF file (requires 'dot' from graphviz)") var graphviz: String?

    func run() throws {
        let baseGraph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)
        for e in baseGraph.edges {
            _ = try weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = Double.random(in: 1.0...20.0).rounded()
        }

        guard let sp = PathsAndCycles.bidirectionalDijkstra(graph: weightedGraph, source: source, target: target) else {
            print("❌ No path found between \(source) and \(target).")
            return
        }

        print("⚡ Shortest Path from \(source) to \(target): \(sp.path)")
        print("📏 Total Distance: \(sp.distance)")

        if let outPath = output {
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: weightedGraph,
                title: "Shortest Path \(source) → \(target) (Distance: \(sp.distance))",
                tourSequence: sp.path
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported Shortest Path visualization to \(outPath)")
        }

        if let gvPath = graphviz {
            let dot = GraphvizExporter.dot(
                graph: weightedGraph,
                title: "Shortest Path \(source) to \(target)",
                tour: sp.path,
                highlightEdges: Set(zip(sp.path, sp.path.dropFirst()).map { Edge(u: $0.0, v: $0.1) })
            )
            try emitGraphviz(dot: dot, to: gvPath)
        }
    }
}

// MARK: - 7. Network Flow Command

struct FlowCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "flow", abstract: "Solve Max Flow and Min-Cost Flow (Topics 8.1 - 8.2)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 6
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let net = try RandomFlowNetwork.build(vertex: vertices, layerCount: 2, minCapacity: 5.0, maxCapacity: 25.0, minCost: 1.0, maxCost: 8.0)
        let (maxF, solvedNet) = AdvancedFlow.dinicMaxFlow(in: net, from: 0, to: vertices - 1)
        print("🌊 Maximum Network Flow (Dinic): \(maxF)")

        if let outPath = output {
            var labels: [Edge: String] = [:]
            var hlEdges = Set<Edge>()
            for e in solvedNet.edges {
                if let attr = solvedNet.edgeProperties[e] {
                    var s = "\(Int(attr.flow))/\(Int(attr.capacity))"
                    if attr.cost != 0 { s += " ($\(Int(attr.cost)))" }
                    labels[e] = s
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
            try svg.write(toFile: outPath, atomically: true, encoding: String.Encoding.utf8)
            print("🖼️ Exported flow network visualization to \(outPath)")
        }
    }
}

// MARK: - 8. Vertex Coloring Command

struct ColorCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "color", abstract: "Vertex Coloring & Chromatic Polynomial (Topics 6.1 - 6.2)")

    @Option(name: .shortAndLong, help: "Number of vertices") var vertices: Int = 8
    @Option(name: .shortAndLong, help: "Number of edges") var edges: Int = 12
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let baseGraph = try RandomConnectedGraph.build(vertex: vertices, edge: edges)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<vertices), kind: .undirected)
        for e in baseGraph.edges {
            _ = try weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = Double.random(in: 1.0...10.0).rounded()
        }

        let result = GraphColoring.color(weightedGraph)
        print("🎨 Chromatic Number χ(G): \(result.chromaticNumber)")
        print("   Color Classes: \(result.colorClasses)")

        if let outPath = output {
            let theme = GraphVisualTheme.modernDark
            var nodeColors: [Int: String] = [:]
            for (v, c) in result.colors {
                nodeColors[v] = theme.palette[c % theme.palette.count]
            }
            let vGraph = try LayoutBridge.layoutSugiyama(
                graph: weightedGraph,
                title: "Vertex Coloring (χ = \(result.chromaticNumber))",
                nodeColors: nodeColors
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported coloring visualization with edge costs to \(outPath)")
        }
    }
}

// MARK: - 9. Matching Command

struct MatchCmd: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "match", abstract: "Solve Maximum & Min-Sum Matching (Topics 7.1 - 7.2)")

    @Option(name: .shortAndLong, help: "Partition size") var size: Int = 4
    @Option(name: .shortAndLong, help: "Output SVG file path") var output: String?

    func run() throws {
        let baseGraph = try BipartiteRandomGraph.build(partition: size, partition: size, edge: size * 2)
        var weightedGraph = AdjacentGraph<Int, Double>(vertices: Array(0..<(size * 2)), kind: .undirected)
        for e in baseGraph.edges {
            _ = try weightedGraph.addEdge(u: e.u, v: e.v)
            weightedGraph[e] = Double.random(in: 1.0...15.0).rounded()
        }

        let uPart = Array(0..<size)
        let vPart = Array(size..<(size * 2))
        let matching = GraphMatching.hopcroftKarp(graph: weightedGraph, partitionV1: Set(uPart))
        print("🤝 Maximum Bipartite Matching: \(matching.cardinality) pairs")
        print("   Matched Edges: \(matching.matchedEdges)")

        if let outPath = output {
            let vGraph = try LayoutBridge.layoutBipartite(
                graph: weightedGraph,
                partitionU: uPart,
                partitionV: vPart,
                labelU: "Workers (U)",
                labelV: "Tasks (V)",
                matchedEdges: Set(matching.matchedEdges)
            )
            let svg = SVGGraphRenderer.renderToSVG(vGraph)
            try svg.write(toFile: outPath, atomically: true, encoding: .utf8)
            print("🖼️ Exported bipartite matching visualization with edge costs to \(outPath)")
        }
    }
}

// MARK: - 10. Planarity Command

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
