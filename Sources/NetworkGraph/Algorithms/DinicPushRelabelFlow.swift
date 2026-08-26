//
//  DinicPushRelabelFlow.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Detailed result of a Minimum Cost Maximum Flow computation.
public struct MinCostFlowResult: Sendable {
    public let maxFlow: Double
    public let totalCost: Double
    public let network: FlowNetwork
}

/// Advanced Network Flow algorithms: Dinic, Push-Relabel, and Min-Cost Max-Flow (Topic 8).
public enum AdvancedFlow {

    // MARK: - 8.1 Dinic's Maximum Flow Algorithm O(V^2 E)

    /// Computes maximum network flow using Dinic's blocking flow algorithm.
    ///
    /// - Parameters:
    ///   - graph: A `FlowNetwork`.
    ///   - source: Source vertex index.
    ///   - sink: Sink vertex index.
    /// - Returns: The maximum flow value and the resulting flow network.
    public static func dinicMaxFlow(
        in graph: FlowNetwork,
        from source: Int,
        to sink: Int
    ) -> (maxFlow: Double, network: FlowNetwork) {
        var net = graph
        let n = net.vertexCount
        for k in net.edgeProperties.keys { net.edgeProperties[k]!.flow = 0 }

        var level = Array(repeating: -1, count: n)

        func bfsLevel() -> Bool {
            level = Array(repeating: -1, count: n)
            level[source] = 0
            var queue = [source]

            while !queue.isEmpty {
                let u = queue.removeFirst()
                for v in net.adjacent(of: u) {
                    let e = Edge(u: u, v: v)
                    if let attr = net.edgeProperties[e], attr.residualCapacity > 0 && level[v] == -1 {
                        level[v] = level[u] + 1
                        queue.append(v)
                    }
                }
                for (p, _) in net.inEdges(vertex: u) {
                    let e = Edge(u: p, v: u)
                    if let attr = net.edgeProperties[e], attr.flow > 0 && level[p] == -1 {
                        level[p] = level[u] + 1
                        queue.append(p)
                    }
                }
            }
            return level[sink] != -1
        }

        func dfsBlock(_ u: Int, _ pushed: Double, _ ptr: inout [Int]) -> Double {
            if pushed == 0 || u == sink { return pushed }

            let adj = net.adjacent(of: u)
            while ptr[u] < adj.count {
                let v = adj[ptr[u]]
                let e = Edge(u: u, v: v)
                if let attr = net.edgeProperties[e], level[v] == level[u] + 1 && attr.residualCapacity > 0 {
                    let tr = dfsBlock(v, Swift.min(pushed, attr.residualCapacity), &ptr)
                    if tr > 0 {
                        net.edgeProperties[e]!.flow += tr
                        return tr
                    }
                }
                ptr[u] += 1
            }

            // Also check backward edges
            for (p, _) in net.inEdges(vertex: u) {
                let e = Edge(u: p, v: u)
                if let attr = net.edgeProperties[e], level[p] == level[u] + 1 && attr.flow > 0 {
                    let tr = dfsBlock(p, Swift.min(pushed, attr.flow), &ptr)
                    if tr > 0 {
                        net.edgeProperties[e]!.flow -= tr
                        return tr
                    }
                }
            }

            return 0
        }

        var totalFlow = 0.0
        while bfsLevel() {
            var ptr = Array(repeating: 0, count: n)
            while true {
                let pushed = dfsBlock(source, Double.infinity, &ptr)
                if pushed == 0 { break }
                totalFlow += pushed
            }
        }

        return (totalFlow, net)
    }

    // MARK: - 8.1 Push-Relabel Maximum Flow Algorithm O(V^3)

    /// Computes maximum flow using the Push-Relabel algorithm with highest-label selection.
    public static func pushRelabelMaxFlow(
        in graph: FlowNetwork,
        from source: Int,
        to sink: Int
    ) -> (maxFlow: Double, network: FlowNetwork) {
        var net = graph
        let n = net.vertexCount
        for k in net.edgeProperties.keys { net.edgeProperties[k]!.flow = 0 }

        var height = Array(repeating: 0, count: n)
        var excess = Array(repeating: 0.0, count: n)
        height[source] = n

        // Initial preflow from source
        for v in net.adjacent(of: source) {
            let e = Edge(u: source, v: v)
            if let attr = net.edgeProperties[e] {
                let cap = attr.capacity
                net.edgeProperties[e]!.flow = cap
                excess[v] += cap
                excess[source] -= cap
            }
        }

        func push(_ u: Int, _ v: Int, _ isForward: Bool) {
            let e = isForward ? Edge(u: u, v: v) : Edge(u: v, v: u)
            let resCap = isForward ? net.edgeProperties[e]!.residualCapacity : net.edgeProperties[e]!.flow
            let send = Swift.min(excess[u], resCap)
            if send > 0 {
                if isForward {
                    net.edgeProperties[e]!.flow += send
                } else {
                    net.edgeProperties[e]!.flow -= send
                }
                excess[u] -= send
                excess[v] += send
            }
        }

        func relabel(_ u: Int) {
            var minH = Int.max
            for v in net.adjacent(of: u) {
                let e = Edge(u: u, v: v)
                if net.edgeProperties[e]!.residualCapacity > 0 {
                    minH = Swift.min(minH, height[v])
                }
            }
            for (p, _) in net.inEdges(vertex: u) {
                let e = Edge(u: p, v: u)
                if net.edgeProperties[e]!.flow > 0 {
                    minH = Swift.min(minH, height[p])
                }
            }
            if minH < Int.max {
                height[u] = minH + 1
            }
        }

        while true {
            // Find active vertex (u != source, u != sink with excess[u] > 0) with max height
            var maxH = -1
            var activeU = -1
            for i in 0..<n where i != source && i != sink && excess[i] > 1e-9 {
                if height[i] > maxH {
                    maxH = height[i]
                    activeU = i
                }
            }

            guard activeU != -1 else { break }
            let u = activeU

            var pushed = false
            for v in net.adjacent(of: u) {
                let e = Edge(u: u, v: v)
                if net.edgeProperties[e]!.residualCapacity > 1e-9 && height[u] == height[v] + 1 {
                    push(u, v, true)
                    pushed = true
                    break
                }
            }
            if !pushed {
                for (p, _) in net.inEdges(vertex: u) {
                    let e = Edge(u: p, v: u)
                    if net.edgeProperties[e]!.flow > 1e-9 && height[u] == height[p] + 1 {
                        push(u, p, false)
                        pushed = true
                        break
                    }
                }
            }
            if !pushed {
                relabel(u)
            }
        }

        let maxFlow = excess[sink]
        return (maxFlow, net)
    }

    // MARK: - 8.2 Minimum Cost Maximum Flow (Successive Shortest Path)

    /// Computes the Minimum Cost Maximum Flow using the Successive Shortest Path algorithm with node potentials.
    public static func minCostMaxFlow(
        in graph: FlowNetwork,
        from source: Int,
        to sink: Int
    ) -> MinCostFlowResult {
        var net = graph
        let n = net.vertexCount
        for k in net.edgeProperties.keys { net.edgeProperties[k]!.flow = 0 }

        var potential = Array(repeating: 0.0, count: n)
        var totalFlow = 0.0
        var totalCost = 0.0

        while true {
            // Dijkstra on residual graph with reduced costs: c_pi(u,v) = cost + pi[u] - pi[v]
            var dist = Array(repeating: Double.infinity, count: n)
            var parentEdge = Array<Edge?>(repeating: nil, count: n)
            var isFwd = Array(repeating: true, count: n)
            dist[source] = 0

            var pq = PriorityQueue<Entry>(ascending: true, startingValues: [Entry(dist: 0, vertex: source)])

            while let entry = pq.pop() {
                let u = entry.vertex
                if entry.dist > dist[u] { continue }

                // Forward edges
                for v in net.adjacent(of: u) {
                    let e = Edge(u: u, v: v)
                    let attr = net.edgeProperties[e]!
                    if attr.residualCapacity > 1e-9 {
                        let reducedCost = attr.cost + potential[u] - potential[v]
                        if dist[u] + reducedCost < dist[v] {
                            dist[v] = dist[u] + reducedCost
                            parentEdge[v] = e
                            isFwd[v] = true
                            pq.push(Entry(dist: dist[v], vertex: v))
                        }
                    }
                }

                // Backward edges
                for (p, _) in net.inEdges(vertex: u) {
                    let e = Edge(u: p, v: u)
                    let attr = net.edgeProperties[e]!
                    if attr.flow > 1e-9 {
                        let reducedCost = -attr.cost + potential[u] - potential[p]
                        if dist[u] + reducedCost < dist[p] {
                            dist[p] = dist[u] + reducedCost
                            parentEdge[p] = e
                            isFwd[p] = false
                            pq.push(Entry(dist: dist[p], vertex: p))
                        }
                    }
                }
            }

            guard dist[sink] != .infinity else { break }

            // Update potentials
            for i in 0..<n {
                if dist[i] != .infinity {
                    potential[i] += dist[i]
                }
            }

            // Find bottleneck capacity along shortest augmenting path
            var bottleneck = Double.infinity
            var curr = sink
            while curr != source {
                guard let e = parentEdge[curr] else { break }
                let attr = net.edgeProperties[e]!
                if isFwd[curr] {
                    bottleneck = Swift.min(bottleneck, attr.residualCapacity)
                    curr = e.u
                } else {
                    bottleneck = Swift.min(bottleneck, attr.flow)
                    curr = e.v
                }
            }

            // Push flow along the path
            curr = sink
            while curr != source {
                guard let e = parentEdge[curr] else { break }
                let attr = net.edgeProperties[e]!
                if isFwd[curr] {
                    net.edgeProperties[e]!.flow += bottleneck
                    totalCost += bottleneck * attr.cost
                    curr = e.u
                } else {
                    net.edgeProperties[e]!.flow -= bottleneck
                    totalCost -= bottleneck * attr.cost
                    curr = e.v
                }
            }

            totalFlow += bottleneck
        }

        return MinCostFlowResult(maxFlow: totalFlow, totalCost: totalCost, network: net)
    }
}
