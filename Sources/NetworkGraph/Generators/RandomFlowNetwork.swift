//
//  RandomFlowNetwork.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Generates random flow networks with guaranteed source-sink reachability (Topic 1.10).
public enum RandomFlowNetwork {

    /// Generates a random flow network on $V$ vertices with source $s=0$, sink $t=V-1$, and random edge capacities.
    ///
    /// - Parameters:
    ///   - V: Total number of vertices ($V \ge 2$).
    ///   - layerCount: Number of internal layers (excluding source and sink).
    ///   - minCapacity: Minimum arc capacity (default 1.0).
    ///   - maxCapacity: Maximum arc capacity (default 20.0).
    ///   - minCost: Minimum arc unit cost (default 1.0).
    ///   - maxCost: Maximum arc unit cost (default 10.0).
    /// - Returns: A `FlowNetwork` configured with source at 0 and sink at $V-1$.
    public static func build(
        vertex V: Int,
        layerCount: Int = 3,
        minCapacity: Double = 1.0,
        maxCapacity: Double = 20.0,
        minCost: Double = 1.0,
        maxCost: Double = 10.0
    ) throws -> FlowNetwork {
        guard V >= 2 else {
            throw NetworkGraphError.illegalArgument(cause: "Flow networks require V >= 2")
        }

        var vertices: [FlowVertex] = []
        for i in 0..<V {
            var fv = FlowVertex(label: "\(i)")
            if i == 0 {
                fv.supply = 0
            } else if i == V - 1 {
                fv.supply = 0
            }
            vertices.append(fv)
        }

        var net = FlowNetwork(vertices: vertices, kind: .directed)

        if V == 2 {
            let cap = Double.random(in: minCapacity...maxCapacity)
            let cost = Double.random(in: minCost...maxCost)
            _ = net._addEdge(u: 0, v: 1)
            net[Edge(u: 0, v: 1)] = FlowEdge(capacity: cap, cost: cost)
            return net
        }

        // Partition intermediate vertices into layers
        let intermediateCount = V - 2
        let actualLayers = Swift.min(layerCount, intermediateCount)
        var layers: [[Int]] = Array(repeating: [], count: actualLayers + 2)
        layers[0] = [0] // Source
        layers[actualLayers + 1] = [V - 1] // Sink

        var available = Array(1..<(V - 1))
        RandomPermutation.shuffle(&available)

        for (idx, v) in available.enumerated() {
            let layerIdx = (idx % actualLayers) + 1
            layers[layerIdx].append(v)
        }

        // Guarantee at least one path from source to sink through consecutive layers
        var path: [Int] = [0]
        for l in 1...actualLayers {
            let choice = layers[l].randomElement()!
            path.append(choice)
        }
        path.append(V - 1)

        for i in 0..<(path.count - 1) {
            let u = path[i]
            let v = path[i + 1]
            if !net.isAdjacent(u: u, v: v) {
                _ = net._addEdge(u: u, v: v)
                let cap = Double.random(in: minCapacity...maxCapacity)
                let cost = Double.random(in: minCost...maxCost)
                net[Edge(u: u, v: v)] = FlowEdge(capacity: cap, cost: cost)
            }
        }

        // Add additional random cross-layer forward arcs
        for l in 0..<(layers.count - 1) {
            for u in layers[l] {
                for nextL in (l + 1)..<layers.count {
                    for v in layers[nextL] {
                        if !net.isAdjacent(u: u, v: v) && Float.random(in: 0...1) < 0.45 {
                            _ = net._addEdge(u: u, v: v)
                            let cap = Double.random(in: minCapacity...maxCapacity)
                            let cost = Double.random(in: minCost...maxCost)
                            net[Edge(u: u, v: v)] = FlowEdge(capacity: cap, cost: cost)
                        }
                    }
                }
            }
        }

        return net
    }
}
