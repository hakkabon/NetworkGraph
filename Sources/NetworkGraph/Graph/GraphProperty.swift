//
//  GraphProperty.swift
//  NetworkGraph
//
//  Created by Ulf Akerstedt-Inoue on 2020/04/27.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public protocol ReadablePropertyMap {
    associatedtype Key
    associatedtype Value
    /// Returns the value for `key`, or `nil` if not present.
    func get(key: Key) -> Value?
    /// Returns the value for `key`, or `defaultValue` if not present.
    func get(key: Key, default defaultValue: Value) -> Value
    /// Returns the value for `key`, or `nil` if not present.
    func value(for key: Key) -> Value?
}

public extension ReadablePropertyMap {
    func value(for key: Key) -> Value? {
        return get(key: key)
    }

    func get(key: Key, default defaultValue: Value) -> Value {
        return get(key: key) ?? defaultValue
    }
}

public protocol WriteablePropertyMap {
    associatedtype Key
    associatedtype Value
    mutating func put(key: Key, value: Value)
}

public protocol ReadWritePropertyMap: ReadablePropertyMap, WriteablePropertyMap {
}

// `PropertyMap` adapter for Swift's Dictionary type
public struct PropertyMap<Key: Hashable, Value>: ReadWritePropertyMap {

    private var dict: [Key: Value]

    public init() {
        self.dict = [Key: Value]()
    }

    public init(dictionary: [Key: Value]) {
        self.dict = dictionary
    }

    /// Returns the value for `key`, or `nil` if not present.
    public func get(key: Key) -> Value? {
        return dict[key]
    }

    /// Returns the value for `key`, or `nil` if not present.
    public func value(for key: Key) -> Value? {
        return dict[key]
    }

    /// Returns the value for `key`, or `defaultValue` if not present.
    public func get(key: Key, default defaultValue: Value) -> Value {
        return dict[key] ?? defaultValue
    }

    // Swift dictionary does not mutate its (key,value) tuples.
    public mutating func put(key: Key, value: Value) {
        // If key already exists in the dictionary, value replaces the existing
        // associated value. If key isn't already a key of the dictionary,
        // the (key, value) pair is added.
        _ = dict.updateValue(value, forKey: key)
    }
}
