//
//  Bernoulli.swift
//  NetworkGraph
//  
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// Returns a random boolean from a Bernoulli distribution with success probability `p`.
/// - Parameter p: p the probability of returning `true`
/// - Throws: unless 0 <= p <= 1.0
/// - Returns: `true` with probability p and `false` with probability 1 - p.
public func bernoulli(_ p: Float) throws -> Bool {
    guard p >= 0.0 && p <= 1.0 else {
        throw NetworkGraphError.illegalArgument(cause: "probability p must be between 0.0 and 1.0: \(p)")
    }
    return Float.random(in: 0...1) < p
}
