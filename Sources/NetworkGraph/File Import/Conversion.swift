//
//  Conversion.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// Converts the contents of a given string to a specified type, which must be one of
/// { Int | Float | Double }.
///
/// - Parameters:
///   - s: the utf-8 bytes to be converted (re-interpreted).
///   - to: type of the result, which must be { Int | Float | Double }
/// - Returns: contents of the type conversion.
public func convert<T>(string s: String, to: T.Type) -> T {
    if T.self == String.self {
        return s as! T
    } else if T.self == Int.self {
        return Int(s) as! T
    } else if T.self == Float.self {
        return Float(s) as! T
    } else if T.self == Double.self {
        return Double(s) as! T
    }
    fatalError()
}
