//
//  Counter.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2021/01/18.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public struct Counter {
    private var count: Int = 0
    public init() {}

    public mutating func callAsFunction(increment: Int = 1) -> Int {
        defer { count += increment }
        return count
    }
}
