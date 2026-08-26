//
//  PackingAndCovering.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Result of a Set Covering / Partitioning computation.
public struct SetCoverResult: Sendable {
    /// Indices of selected subsets.
    public let selectedSubsets: [Int]
    /// Total cost / weight of selected subsets.
    public let totalCost: Double
    /// `true` if every element is covered.
    public let isComplete: Bool
}

/// Result of a Multiple Knapsack computation.
public struct MultipleKnapsackResult: Sendable {
    /// For each knapsack bin, the list of item indices placed in that bin.
    public let binAssignments: [[Int]]
    /// Total profit earned across all packed items.
    public let totalProfit: Double
}

/// Result of a Quadratic Assignment computation.
public struct QAPResult: Sendable {
    /// Permutation mapping: facility $i$ is placed at location `assignment[i]`.
    public let assignment: [Int]
    /// Total quadratic cost $\sum_{i,j} F_{ij} D_{p(i)p(j)} + \sum_i C_{ip(i)}$.
    public let totalCost: Double
}

/// Packing and Covering problem solvers (Topic 9).
public enum PackingAndCovering {

    // MARK: - 9.1 Linear Sum Assignment Problem

    /// Solves the standard Linear Sum Assignment Problem on an $n \times n$ cost matrix in $O(n^3)$ time.
    public static func linearAssignment(costMatrix: [[Double]]) -> (assignment: [Int], totalCost: Double) {
        GraphMatching.hungarianAssignment(costMatrix: costMatrix)
    }

    // MARK: - 9.2 Bottleneck Assignment Problem

    /// Solves the Bottleneck Assignment Problem ($\min \max c_{ij}$) on an $n \times n$ cost matrix via threshold binary search and Hopcroft-Karp bipartite matching.
    public static func bottleneckAssignment(costMatrix: [[Double]]) -> (assignment: [Int], bottleneckCost: Double) {
        let n = costMatrix.count
        guard n > 0 else { return ([], 0.0) }

        // Collect and sort all distinct edge costs
        var distinctCosts = Set<Double>()
        for r in costMatrix { for c in r { distinctCosts.insert(c) } }
        let sortedCosts = distinctCosts.sorted()

        var low = 0
        var high = sortedCosts.count - 1
        var bestCost = sortedCosts[high]
        var bestAssignment = Array(0..<n)

        while low <= high {
            let mid = (low + high) / 2
            let threshold = sortedCosts[mid]

            // Build threshold bipartite graph
            var g = AdjacentGraph<Int, NoProperty>(vertices: Array(0..<(2 * n)), kind: .undirected)
            for i in 0..<n {
                for j in 0..<n {
                    if costMatrix[i][j] <= threshold {
                        _ = g.addEdge(u: i, v: n + j)
                    }
                }
            }

            let matching = GraphMatching.hopcroftKarp(graph: g, partitionV1: Set(0..<n))
            if matching.cardinality == n {
                bestCost = threshold
                var assign = Array(repeating: -1, count: n)
                for (u, v) in matching.matchOf where u < n {
                    assign[u] = v - n
                }
                bestAssignment = assign
                high = mid - 1
            } else {
                low = mid + 1
            }
        }

        return (bestAssignment, bestCost)
    }

    // MARK: - 9.3 Quadratic Assignment Problem (QAP)

    /// Solves the Quadratic Assignment Problem (QAP) minimizing $\sum_{i,j} F_{ij} D_{p(i)p(j)}$:
    /// - $F$: Flow matrix between facilities.
    /// - $D$: Distance matrix between locations.
    public static func quadraticAssignment(
        flowMatrix F: [[Double]],
        distanceMatrix D: [[Double]],
        maxIterations: Int = 1000
    ) -> QAPResult {
        let n = F.count
        guard n > 0 else { return QAPResult(assignment: [], totalCost: 0) }

        func evaluate(_ p: [Int]) -> Double {
            var cost = 0.0
            for i in 0..<n {
                for j in 0..<n {
                    cost += F[i][j] * D[p[i]][p[j]]
                }
            }
            return cost
        }

        // Branch-and-bound for small n (<= 8)
        if n <= 8 {
            var bestP = Array(0..<n)
            var minCost = Double.infinity

            func permuteAll(arr: inout [Int], k: Int) {
                if k == n {
                    let c = evaluate(arr)
                    if c < minCost {
                        minCost = c
                        bestP = arr
                    }
                    return
                }
                for i in k..<n {
                    arr.swapAt(k, i)
                    permuteAll(arr: &arr, k: k + 1)
                    arr.swapAt(k, i)
                }
            }

            var p = Array(0..<n)
            permuteAll(arr: &p, k: 0)
            return QAPResult(assignment: bestP, totalCost: minCost)
        }

        // 2-Opt Local Search heuristic for larger n
        var bestP = RandomPermutation.generate(n: n)
        var bestCost = evaluate(bestP)
        var improved = true

        for _ in 0..<maxIterations where improved {
            improved = false
            for i in 0..<(n - 1) {
                for j in (i + 1)..<n {
                    var candidate = bestP
                    candidate.swapAt(i, j)
                    let candCost = evaluate(candidate)
                    if candCost < bestCost {
                        bestCost = candCost
                        bestP = candidate
                        improved = true
                    }
                }
            }
        }

        return QAPResult(assignment: bestP, totalCost: bestCost)
    }

    // MARK: - 9.4 Multiple Knapsack Problem

    /// Solves the 0-1 Multiple Knapsack Problem packing $n$ items into $m$ distinct capacity bins.
    ///
    /// - Parameters:
    ///   - profits: Profit $p_i$ of each item $i$.
    ///   - weights: Weight $w_i$ of each item $i$.
    ///   - capacities: Capacity $C_j$ of each knapsack bin $j$.
    /// - Returns: A `MultipleKnapsackResult` with assignments per bin and total profit.
    public static func multipleKnapsack(
        profits: [Double],
        weights: [Double],
        capacities: [Double]
    ) -> MultipleKnapsackResult {
        let n = profits.count
        let m = capacities.count
        guard n > 0 && m > 0 else {
            return MultipleKnapsackResult(binAssignments: Array(repeating: [], count: m), totalProfit: 0)
        }

        // Branch-and-bound search
        var bestAssignment = Array(repeating: -1, count: n) // item -> bin
        var bestProfit = 0.0

        var currentAssignment = Array(repeating: -1, count: n)
        var remainingCap = capacities

        func search(item: Int, currentProfit: Double) {
            if item == n {
                if currentProfit > bestProfit {
                    bestProfit = currentProfit
                    bestAssignment = currentAssignment
                }
                return
            }

            // Option 1: Try placing item in each bin
            let w = weights[item]
            let p = profits[item]

            for bin in 0..<m {
                if remainingCap[bin] >= w {
                    remainingCap[bin] -= w
                    currentAssignment[item] = bin
                    search(item: item + 1, currentProfit: currentProfit + p)
                    currentAssignment[item] = -1
                    remainingCap[bin] += w
                }
            }

            // Option 2: Skip item
            search(item: item + 1, currentProfit: currentProfit)
        }

        search(item: 0, currentProfit: 0.0)

        var binResults = Array(repeating: [Int](), count: m)
        for (item, bin) in bestAssignment.enumerated() where bin != -1 {
            binResults[bin].append(item)
        }

        return MultipleKnapsackResult(binAssignments: binResults, totalProfit: bestProfit)
    }

    // MARK: - 9.5 Set Covering Problem

    /// Solves the Set Covering Problem: finds a minimum-weight collection of subsets whose union covers the universe $U = \{0, 1, \dots, |U|-1\}$.
    ///
    /// - Parameters:
    ///   - universeSize: Total elements $|U|$ in universe.
    ///   - subsets: Array of subsets (each an array of element indices in $0..<universeSize$).
    ///   - costs: Optional cost for each subset (defaults to 1.0 per subset for minimum cardinality).
    ///   - exact: If `true`, runs exact branch-and-bound; if `false`, runs Chvátal greedy $\ln |U|$ approximation.
    /// - Returns: A `SetCoverResult` with chosen subset indices.
    public static func setCover(
        universeSize: Int,
        subsets: [[Int]],
        costs: [Double]? = nil,
        exact: Bool = true
    ) -> SetCoverResult {
        let m = subsets.count
        let costArr = costs ?? Array(repeating: 1.0, count: m)
        let subBitsets = subsets.map { BitVector(size: universeSize, bitPattern: $0) }

        if exact && universeSize <= 30 && m <= 30 {
            // Exact Bitmask Branch & Bound
            var bestCost = Double.infinity
            var bestChoice: [Int] = []

            func bb(subsetIdx: Int, currentCover: BitVector, currentCost: Double, chosen: [Int]) {
                if currentCover.count == universeSize {
                    if currentCost < bestCost {
                        bestCost = currentCost
                        bestChoice = chosen
                    }
                    return
                }
                if subsetIdx == m || currentCost >= bestCost { return }

                // Branch 1: include subset
                let nextCover = currentCover.union(subBitsets[subsetIdx])
                bb(subsetIdx: subsetIdx + 1, currentCover: nextCover, currentCost: currentCost + costArr[subsetIdx], chosen: chosen + [subsetIdx])

                // Branch 2: exclude subset
                bb(subsetIdx: subsetIdx + 1, currentCover: currentCover, currentCost: currentCost, chosen: chosen)
            }

            bb(subsetIdx: 0, currentCover: BitVector(size: universeSize), currentCost: 0, chosen: [])
            return SetCoverResult(selectedSubsets: bestChoice, totalCost: bestCost, isComplete: bestChoice.count > 0)
        }

        // Chvátal Greedy Set Cover Approximation
        var uncovered = BitVector(size: universeSize, bitPattern: Array(0..<universeSize))
        var selected: [Int] = []
        var totalCost = 0.0

        while !uncovered.isEmpty {
            var bestIdx = -1
            var bestEfficiency = Double.infinity // cost per newly covered element

            for i in 0..<m {
                let newlyCovered = subBitsets[i].intersection(uncovered).count
                if newlyCovered > 0 {
                    let eff = costArr[i] / Double(newlyCovered)
                    if eff < bestEfficiency {
                        bestEfficiency = eff
                        bestIdx = i
                    }
                }
            }

            guard bestIdx != -1 else { break }

            selected.append(bestIdx)
            totalCost += costArr[bestIdx]
            uncovered = uncovered.difference(subBitsets[bestIdx])
        }

        return SetCoverResult(
            selectedSubsets: selected,
            totalCost: totalCost,
            isComplete: uncovered.isEmpty
        )
    }

    // MARK: - 9.6 Set Partitioning Problem (Exact Cover)

    /// Solves the Set Partitioning Problem (Exact Cover): finds a collection of mutually disjoint subsets whose union is exactly the universe.
    ///
    /// - Parameters:
    ///   - universeSize: Number of elements in universe.
    ///   - subsets: Array of subsets.
    /// - Returns: A `SetCoverResult` with chosen disjoint subsets.
    public static func setPartitioning(
        universeSize: Int,
        subsets: [[Int]],
        costs: [Double]? = nil
    ) -> SetCoverResult? {
        let m = subsets.count
        let costArr = costs ?? Array(repeating: 1.0, count: m)
        let subBitsets = subsets.map { BitVector(size: universeSize, bitPattern: $0) }

        var bestChoice: [Int]? = nil
        var minCost = Double.infinity

        func solve(subsetIdx: Int, currentCover: BitVector, currentCost: Double, chosen: [Int]) {
            if currentCover.count == universeSize {
                if currentCost < minCost {
                    minCost = currentCost
                    bestChoice = chosen
                }
                return
            }
            if subsetIdx == m || currentCost >= minCost { return }

            // Can we take subsetIdx? Must be completely disjoint from currentCover
            if !currentCover.intersects(subBitsets[subsetIdx]) {
                let nextCover = currentCover.union(subBitsets[subsetIdx])
                solve(subsetIdx: subsetIdx + 1, currentCover: nextCover, currentCost: currentCost + costArr[subsetIdx], chosen: chosen + [subsetIdx])
            }

            // Option 2: skip subsetIdx
            solve(subsetIdx: subsetIdx + 1, currentCover: currentCover, currentCost: currentCost, chosen: chosen)
        }

        solve(subsetIdx: 0, currentCover: BitVector(size: universeSize), currentCost: 0, chosen: [])

        guard let choice = bestChoice else { return nil }
        return SetCoverResult(selectedSubsets: choice, totalCost: minCost, isComplete: true)
    }
}
