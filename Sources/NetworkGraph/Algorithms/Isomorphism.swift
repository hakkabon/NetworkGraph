//
//  Isomorphism.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Result of a Graph Isomorphism test.
public struct IsomorphismResult: Sendable {
    /// `true` if $G_1 \cong G_2$.
    public let isIsomorphic: Bool
    /// If isomorphic, the bijective mapping $\pi: V(G_1) \to V(G_2)$.
    public let mapping: [Int: Int]?
}

/// Graph Isomorphism Testing algorithms (Topic 5).
public enum GraphIsomorphism {

    /// Tests if graph $G_1$ is isomorphic to graph $G_2$ and returns the bijective vertex mapping if isomorphic.
    public static func areIsomorphic<V1, W1, V2, W2>(
        _ g1: AdjacentGraph<V1, W1>,
        _ g2: AdjacentGraph<V2, W2>
    ) -> IsomorphismResult {
        let n1 = g1.vertexCount
        let n2 = g2.vertexCount
        guard n1 == n2 else { return IsomorphismResult(isIsomorphic: false, mapping: nil) }
        guard g1.edgeCount == g2.edgeCount else { return IsomorphismResult(isIsomorphic: false, mapping: nil) }
        if n1 == 0 { return IsomorphismResult(isIsomorphic: true, mapping: [:]) }

        // Degree sequence quick check
        var deg1 = (0..<n1).map { g1.degree(vertex: $0) }.sorted()
        var deg2 = (0..<n2).map { g2.degree(vertex: $0) }.sorted()
        guard deg1 == deg2 else { return IsomorphismResult(isIsomorphic: false, mapping: nil) }

        // 1-WL (Weisfeiler-Lehman / Color Refinement) test
        let (wl1, wl2) = weisfeilerLehmanRefinement(g1, g2)
        guard wl1.sorted() == wl2.sorted() else {
            return IsomorphismResult(isIsomorphic: false, mapping: nil)
        }

        // VF2 state-space search for exact bijection
        return vf2Match(g1, g2, colors1: wl1, colors2: wl2)
    }

    // MARK: - 1-WL Color Refinement

    private static func weisfeilerLehmanRefinement<V1, W1, V2, W2>(
        _ g1: AdjacentGraph<V1, W1>,
        _ g2: AdjacentGraph<V2, W2>,
        iterations: Int = 5
    ) -> ([Int], [Int]) {
        let n = g1.vertexCount
        var c1 = (0..<n).map { g1.degree(vertex: $0) }
        var c2 = (0..<n).map { g2.degree(vertex: $0) }

        for _ in 0..<iterations {
            var signatureMap: [[Int]: Int] = [:]
            var nextColorId = 0

            var nextC1 = [Int](repeating: 0, count: n)
            for u in 0..<n {
                let neighborColors = g1.adjacent(of: u).map { c1[$0] }.sorted()
                let sig = [c1[u]] + neighborColors
                if let cid = signatureMap[sig] {
                    nextC1[u] = cid
                } else {
                    signatureMap[sig] = nextColorId
                    nextC1[u] = nextColorId
                    nextColorId += 1
                }
            }

            var nextC2 = [Int](repeating: 0, count: n)
            for u in 0..<n {
                let neighborColors = g2.adjacent(of: u).map { c2[$0] }.sorted()
                let sig = [c2[u]] + neighborColors
                if let cid = signatureMap[sig] {
                    nextC2[u] = cid
                } else {
                    signatureMap[sig] = nextColorId
                    nextC2[u] = nextColorId
                    nextColorId += 1
                }
            }

            c1 = nextC1
            c2 = nextC2
        }

        return (c1, c2)
    }

    // MARK: - VF2 Algorithm

    private static func vf2Match<V1, W1, V2, W2>(
        _ g1: AdjacentGraph<V1, W1>,
        _ g2: AdjacentGraph<V2, W2>,
        colors1: [Int],
        colors2: [Int]
    ) -> IsomorphismResult {
        let n = g1.vertexCount
        var core1 = Array(repeating: -1, count: n)
        var core2 = Array(repeating: -1, count: n)

        func isFeasible(u: Int, v: Int) -> Bool {
            if colors1[u] != colors2[v] { return false }
            if g1.degree(vertex: u) != g2.degree(vertex: v) { return false }
            if g1.indegree(vertex: u) != g2.indegree(vertex: v) { return false }

            // Consistency with existing matching
            for adjU in g1.adjacent(of: u) {
                if core1[adjU] != -1 {
                    let matchedV = core1[adjU]
                    if !g2.isAdjacent(u: v, v: matchedV) { return false }
                }
            }
            for adjV in g2.adjacent(of: v) {
                if core2[adjV] != -1 {
                    let matchedU = core2[adjV]
                    if !g1.isAdjacent(u: u, v: matchedU) { return false }
                }
            }
            return true
        }

        func match(depth: Int) -> Bool {
            if depth == n { return true }

            // Pick first unmatched vertex in g1
            var u = 0
            while u < n && core1[u] != -1 { u += 1 }
            if u == n { return true }

            for v in 0..<n where core2[v] == -1 {
                if isFeasible(u: u, v: v) {
                    core1[u] = v
                    core2[v] = u
                    if match(depth: depth + 1) {
                        return true
                    }
                    core1[u] = -1
                    core2[v] = -1
                }
            }
            return false
        }

        if match(depth: 0) {
            var mapping: [Int: Int] = [:]
            for i in 0..<n {
                mapping[i] = core1[i]
            }
            return IsomorphismResult(isIsomorphic: true, mapping: mapping)
        }

        return IsomorphismResult(isIsomorphic: false, mapping: nil)
    }

    // MARK: - Tree Isomorphism (AHU Algorithm O(V))

    /// Fast $O(V)$ canonical string encoding for rooted and unrooted tree isomorphism.
    public static func areTreesIsomorphic<V1, W1, V2, W2>(
        _ t1: AdjacentGraph<V1, W1>,
        _ t2: AdjacentGraph<V2, W2>
    ) -> Bool {
        guard t1.vertexCount == t2.vertexCount else { return false }
        let n = t1.vertexCount
        if n <= 1 { return true }

        let c1 = findTreeCenters(t1)
        let c2 = findTreeCenters(t2)

        for root1 in c1 {
            let canon1 = ahuCanonicalString(t1, root: root1)
            for root2 in c2 {
                let canon2 = ahuCanonicalString(t2, root: root2)
                if canon1 == canon2 { return true }
            }
        }
        return false
    }

    private static func findTreeCenters<V, W>(_ tree: AdjacentGraph<V, W>) -> [Int] {
        let n = tree.vertexCount
        var deg = (0..<n).map { tree.degree(vertex: $0) }
        var leaves = (0..<n).filter { deg[$0] <= 1 }
        var remaining = n

        while remaining > 2 {
            remaining -= leaves.count
            var newLeaves: [Int] = []
            for leaf in leaves {
                for neighbor in tree.adjacent(of: leaf) {
                    deg[neighbor] -= 1
                    if deg[neighbor] == 1 {
                        newLeaves.append(neighbor)
                    }
                }
            }
            leaves = newLeaves
        }
        return leaves
    }

    private static func ahuCanonicalString<V, W>(_ tree: AdjacentGraph<V, W>, root: Int) -> String {
        func encode(_ u: Int, _ p: Int) -> String {
            var childCodes: [String] = []
            for v in tree.adjacent(of: u) where v != p {
                childCodes.append(encode(v, u))
            }
            childCodes.sort()
            return "1" + childCodes.joined() + "0"
        }
        return encode(root, -1)
    }
}
