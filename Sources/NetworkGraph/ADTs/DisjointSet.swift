//
//  DisjointSet.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// A Disjoint-Set (Union-Find) data structure with path compression and union-by-rank.
///
/// Provides near $O(1)$ amortized time ($\alpha(n)$ inverse Ackermann) for `find` and `union` operations.
public struct DisjointSet {

    private var parent: [Int]
    private var rank: [Int]
    private var size: [Int]
    
    /// Total number of disjoint sets / components.
    public private(set) var count: Int

    /// Initializes a DisjointSet with `size` independent elements [0 ..< size].
    public init(size: Int) {
        self.parent = Array(0..<size)
        self.rank = Array(repeating: 0, count: size)
        self.size = Array(repeating: 1, count: size)
        self.count = size
    }

    /// Finds the representative (root) of the set containing element `i` with path compression.
    public mutating func find(_ i: Int) -> Int {
        guard i >= 0 && i < parent.count else {
            preconditionFailure("Index \(i) out of bounds for DisjointSet of size \(parent.count)")
        }
        var root = i
        while root != parent[root] {
            root = parent[root]
        }
        // Path compression
        var curr = i
        while curr != root {
            let next = parent[curr]
            parent[curr] = root
            curr = next
        }
        return root
    }

    /// Unites the sets containing elements `i` and `j`.
    /// - Returns: `true` if `i` and `j` were in different sets and merged; `false` if they were already in the same set.
    @discardableResult
    public mutating func union(_ i: Int, _ j: Int) -> Bool {
        let rootI = find(i)
        let rootJ = find(j)

        if rootI == rootJ {
            return false
        }

        // Union by rank
        if rank[rootI] < rank[rootJ] {
            parent[rootI] = rootJ
            size[rootJ] += size[rootI]
        } else if rank[rootI] > rank[rootJ] {
            parent[rootJ] = rootI
            size[rootI] += size[rootJ]
        } else {
            parent[rootJ] = rootI
            rank[rootI] += 1
            size[rootI] += size[rootJ]
        }

        count -= 1
        return true
    }

    /// Returns `true` if `i` and `j` belong to the same set.
    public mutating func connected(_ i: Int, _ j: Int) -> Bool {
        find(i) == find(j)
    }

    /// Returns the number of elements in the set containing `i`.
    public mutating func setSize(of i: Int) -> Int {
        let root = find(i)
        return size[root]
    }
}
