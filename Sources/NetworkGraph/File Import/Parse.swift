//
//  Parse.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

extension Array {
    public func splat2() -> (Element,Element) {
        return (self[0],self[1])
    }

    public func splat3() -> (Element,Element,Element) {
        return (self[0],self[1],self[2])
    }

    public func splat4() -> (Element,Element,Element,Element) {
        return (self[0],self[1],self[2],self[3])
    }

    public func splat5() -> (Element,Element,Element,Element,Element) {
        return (self[0],self[1],self[2],self[3],self[4])
    }
}

public func csvparse(file: String, ofType type: String, separator: String) throws -> [[String]] {
    var strings : [[String]] = []
    if let path = Bundle.main.path(forResource: file, ofType: type) {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let encoded = String(data: data, encoding: .utf8)!
        strings.append(contentsOf: encoded.components(separatedBy: .newlines)
                        .map { $0.components(separatedBy: separator).filter { !$0.isEmpty } }
                        .filter { $0 != [] } )
    }
    return strings
}

public func csvparse(string: String, separator: String) -> [[String]] {
    var strings : [[String]] = []
    strings.append(contentsOf: string.components(separatedBy: .newlines)
                    .map { $0.components(separatedBy: separator).filter { !$0.isEmpty } }
                    .filter { $0 != [] } )
    return strings
}


public func read(file: String, ofType type: String, separator: String) throws -> [[String]] {
    var strings : [[String]] = []
    if let filepath = Bundle.main.path(forResource: file, ofType: type) {
        do {
            let contents = try String(contentsOfFile: filepath)
            strings.append(contentsOf: contents.components(separatedBy: .newlines)
                            .map { $0.components(separatedBy: separator).filter { !$0.isEmpty } }
                            .filter { $0 != [] }
            )
        }
    }
    return strings
}
