//
//  ADTTests.swift
//  NetworkGraphTests
//
//  Copyright © 2024 hakkabon software. All rights reserved.
//

import XCTest
@testable import NetworkGraph

final class ADTTests: XCTestCase {

    func testDisjointSet() {
        var ds = DisjointSet(size: 10)
        XCTAssertEqual(ds.count, 10)
        XCTAssertFalse(ds.connected(0, 1))

        XCTAssertTrue(ds.union(0, 1))
        XCTAssertTrue(ds.connected(0, 1))
        XCTAssertEqual(ds.count, 9)
        XCTAssertEqual(ds.setSize(of: 0), 2)

        XCTAssertTrue(ds.union(1, 2))
        XCTAssertTrue(ds.connected(0, 2))
        XCTAssertEqual(ds.setSize(of: 2), 3)

        // Redundant union returns false
        XCTAssertFalse(ds.union(0, 2))
        XCTAssertEqual(ds.count, 8)

        // Connect 3,4 and 5,6 then merge
        ds.union(3, 4)
        ds.union(5, 6)
        ds.union(4, 5)
        XCTAssertTrue(ds.connected(3, 6))
        XCTAssertFalse(ds.connected(0, 3))
    }

    func testBitVector() {
        var bv = BitVector(size: 128)
        XCTAssertEqual(bv.count, 0)
        XCTAssertTrue(bv.isEmpty)

        bv.set(5)
        bv.set(65)
        XCTAssertTrue(bv.get(5))
        XCTAssertTrue(bv.get(65))
        XCTAssertFalse(bv.get(64))
        XCTAssertEqual(bv.count, 2)

        bv.toggle(5)
        XCTAssertFalse(bv.get(5))
        XCTAssertEqual(bv.count, 1)

        bv.clear(65)
        XCTAssertTrue(bv.isEmpty)

        var bv1 = BitVector(size: 10, bitPattern: [1, 3, 5])
        var bv2 = BitVector(size: 10, bitPattern: [3, 7])
        let u = bv1.union(bv2)
        XCTAssertEqual(u.indices, [1, 3, 5, 7])

        let inter = bv1.intersection(bv2)
        XCTAssertEqual(inter.indices, [3])

        let diff = bv1.difference(bv2)
        XCTAssertEqual(diff.indices, [1, 5])
        XCTAssertTrue(bv1.intersects(bv2))
    }
}
