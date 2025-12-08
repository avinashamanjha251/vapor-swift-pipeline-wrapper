//
//  NestedDocumentBuilder.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 09/12/25.
//

import SwiftBSON

// MARK: - Nested Document Builder
class NestedDocumentBuilder {
    private var fields: BSONDocument = [:]
    
    // Add string field reference
    @discardableResult
    func add(_ key: String, string field: String) -> Self {
        fields[key] = .string("$\(field)")
        return self
    }
    
    // Add array element at index
    @discardableResult
    func add(_ key: String, array field: String, index: Int = 0) -> Self {
        fields[key] = .document([
            "$arrayElemAt": .array([.string("$\(field)"), .int32(Int32(index))])
        ])
        return self
    }
    
    // Add first element from array
    @discardableResult
    func add(_ key: String, first field: String) -> Self {
        fields[key] = .document([
            "$first": .string("$\(field)")
        ])
        return self
    }
    
    // Add last element from array
    @discardableResult
    func add(_ key: String, last field: String) -> Self {
        fields[key] = .document([
            "$last": .string("$\(field)")
        ])
        return self
    }
    
    // Add literal value
    @discardableResult
    func add(_ key: String, literal value: BSON) -> Self {
        fields[key] = .document([
            "$literal": value
        ])
        return self
    }
    
    // Add raw BSON
    @discardableResult
    func add(_ key: String, raw value: BSON) -> Self {
        fields[key] = value
        return self
    }
    
    // Add conditional
    @discardableResult
    func add(_ key: String, ifNull field: String, default defaultValue: BSON) -> Self {
        fields[key] = .document([
            "$ifNull": .array([.string("$\(field)"), defaultValue])
        ])
        return self
    }
    
    // Add condition
    @discardableResult
    func add(_ key: String, cond condition: BSON, then thenValue: BSON, else elseValue: BSON) -> Self {
        fields[key] = .document([
            "$cond": .array([condition, thenValue, elseValue])
        ])
        return self
    }
    
    // Add concat
    @discardableResult
    func add(_ key: String, concat values: [BSON]) -> Self {
        fields[key] = .document([
            "$concat": .array(values)
        ])
        return self
    }
    
    // Add sum
    @discardableResult
    func add(_ key: String, sum values: [BSON]) -> Self {
        fields[key] = .document([
            "$add": .array(values)
        ])
        return self
    }
    
    // Add multiply
    @discardableResult
    func add(_ key: String, multiply values: [BSON]) -> Self {
        fields[key] = .document([
            "$multiply": .array(values)
        ])
        return self
    }
    
    // Add divide
    @discardableResult
    func add(_ key: String, divide dividend: BSON, by divisor: BSON) -> Self {
        fields[key] = .document([
            "$divide": .array([dividend, divisor])
        ])
        return self
    }
    
    // Add subtract
    @discardableResult
    func add(_ key: String, subtract minuend: BSON, from subtrahend: BSON) -> Self {
        fields[key] = .document([
            "$subtract": .array([minuend, subtrahend])
        ])
        return self
    }
    
    // Add ceil
    @discardableResult
    func add(_ key: String, ceil value: BSON) -> Self {
        fields[key] = .document([
            "$ceil": value
        ])
        return self
    }
    
    // Add floor
    @discardableResult
    func add(_ key: String, floor value: BSON) -> Self {
        fields[key] = .document([
            "$floor": value
        ])
        return self
    }
    
    // Add round
    @discardableResult
    func add(_ key: String, round value: BSON, place: Int? = nil) -> Self {
        if let place = place {
            fields[key] = .document([
                "$round": .array([value, .int32(Int32(place))])
            ])
        } else {
            fields[key] = .document([
                "$round": value
            ])
        }
        return self
    }
    
    // Add size
    @discardableResult
    func add(_ key: String, size array: String) -> Self {
        fields[key] = .document([
            "$size": .string("$\(array)")
        ])
        return self
    }
    
    // Add merge objects
    @discardableResult
    func add(_ key: String, merge objects: [BSON]) -> Self {
        fields[key] = .document([
            "$mergeObjects": .array(objects)
        ])
        return self
    }
    
    // Add nested document builder
    @discardableResult
    func add(_ key: String, nested: (NestedDocumentBuilder) -> Void) -> Self {
        let builder = NestedDocumentBuilder()
        nested(builder)
        fields[key] = .document(builder.build())
        return self
    }
    
    // Build the document
    func build() -> BSONDocument {
        return fields
    }
}
