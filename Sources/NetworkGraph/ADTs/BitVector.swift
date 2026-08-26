//
//  BitVector.swift
//  NetworkGraph
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import Foundation

/// A fixed-capacity bitset for high-speed combinatorial bitmask operations.
public struct BitVector: Hashable, Codable, Sendable {
    public private(set) var words: [UInt64]
    public let size: Int

    public init(size: Int) {
        self.size = size
        let numWords = (size + 63) / 64
        self.words = Array(repeating: 0, count: numWords)
    }

    public init(size: Int, bitPattern: [Int]) {
        self.init(size: size)
        for bit in bitPattern {
            set(bit)
        }
    }

    public mutating func set(_ index: Int) {
        guard index >= 0 && index < size else { return }
        words[index / 64] |= (1 << (index % 64))
    }

    public mutating func clear(_ index: Int) {
        guard index >= 0 && index < size else { return }
        words[index / 64] &= ~(1 << (index % 64))
    }

    public mutating func toggle(_ index: Int) {
        guard index >= 0 && index < size else { return }
        words[index / 64] ^= (1 << (index % 64))
    }

    public func get(_ index: Int) -> Bool {
        guard index >= 0 && index < size else { return false }
        return (words[index / 64] & (1 << (index % 64))) != 0
    }

    public subscript(index: Int) -> Bool {
        get { get(index) }
        set {
            if newValue { set(index) } else { clear(index) }
        }
    }

    /// Number of set bits (popcount / Hamming weight).
    public var count: Int {
        words.reduce(0) { $0 + $1.nonzeroBitCount }
    }

    public var isEmpty: Bool {
        words.allSatisfy { $0 == 0 }
    }

    public func union(_ other: BitVector) -> BitVector {
        var result = BitVector(size: Swift.max(self.size, other.size))
        let minCount = Swift.min(self.words.count, other.words.count)
        for i in 0..<minCount {
            result.words[i] = self.words[i] | other.words[i]
        }
        if self.words.count > minCount {
            for i in minCount..<self.words.count { result.words[i] = self.words[i] }
        } else if other.words.count > minCount {
            for i in minCount..<other.words.count { result.words[i] = other.words[i] }
        }
        return result
    }

    public func intersection(_ other: BitVector) -> BitVector {
        var result = BitVector(size: Swift.min(self.size, other.size))
        let minCount = Swift.min(self.words.count, other.words.count)
        for i in 0..<minCount {
            result.words[i] = self.words[i] & other.words[i]
        }
        return result
    }

    public func difference(_ other: BitVector) -> BitVector {
        var result = BitVector(size: self.size)
        for i in 0..<self.words.count {
            let otherWord = i < other.words.count ? other.words[i] : 0
            result.words[i] = self.words[i] & ~otherWord
        }
        return result
    }

    public func intersects(_ other: BitVector) -> Bool {
        let minCount = Swift.min(self.words.count, other.words.count)
        for i in 0..<minCount {
            if (self.words[i] & other.words[i]) != 0 {
                return true
            }
        }
        return false
    }

    public var indices: [Int] {
        var result: [Int] = []
        for i in 0..<size {
            if get(i) { result.append(i) }
        }
        return result
    }
}
