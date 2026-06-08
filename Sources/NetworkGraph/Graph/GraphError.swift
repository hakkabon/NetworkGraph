//
//  GraphError.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// Errors throvn by Network Graph.
public enum NetworkGraphError: Swift.Error {
    case illegalArgument(cause: String)
    case undefinedGraphColor
}
