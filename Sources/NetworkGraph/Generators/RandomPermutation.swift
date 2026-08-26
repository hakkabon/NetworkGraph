//
//  RandomPermutation.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// Provides uniform random permutations and shuffles (Topic 1.1).
public enum RandomPermutation {

    /// Returns a random permutation of integers [0 ..< n] using the Fisher-Yates (Knuth) shuffle in $O(n)$ time.
    ///
    /// - Parameter n: The number of elements to permute (must be non-negative).
    /// - Returns: An array containing the permuted indices `0 ..< n`.
    public static func generate(n: Int) -> [Int] {
        guard n > 0 else { return [] }
        var array = Array(0..<n)
        shuffle(&array)
        return array
    }

    /// In-place Fisher-Yates shuffle of a generic mutable collection.
    ///
    /// - Parameter array: The collection to shuffle in-place.
    public static func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in (1..<array.count).reversed() {
            let j = Int.random(in: 0...i)
            if i != j {
                array.swapAt(i, j)
            }
        }
    }

    /// Returns a new array with elements uniformly shuffled.
    public static func shuffled<T>(_ array: [T]) -> [T] {
        var copy = array
        shuffle(&copy)
        return copy
    }
}
