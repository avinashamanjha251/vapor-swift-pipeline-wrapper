//
//  AggregationBuilder.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 06/12/25.
//

import SwiftBSON

// MARK: - Aggregation Field Enum (Same as before)

enum AggField {
    case first(String, field: String)
    case last(String, field: String)
    case sum(String, field: String)
    case avg(String, field: String)
    case min(String, field: String)
    case max(String, field: String)
    case count(String)
    case push(String, field: String)
    case addToSet(String, field: String)
    case sumIf(String, condition: String, equals: String, then: String, elseMultiply: Int)
    
    var keyValue: (String, BSON) {
        switch self {
        case .first(let key, let field):
            return (key, .document(["$first": .string(field)]))
        case .last(let key, let field):
            return (key, .document(["$last": .string(field)]))
        case .sum(let key, let field):
            return (key, .document(["$sum": .string(field)]))
        case .avg(let key, let field):
            return (key, .document(["$avg": .string(field)]))
        case .min(let key, let field):
            return (key, .document(["$min": .string(field)]))
        case .max(let key, let field):
            return (key, .document(["$max": .string(field)]))
        case .count(let key):
            return (key, .document(["$sum": .int32(1)]))
        case .push(let key, let field):
            return (key, .document(["$push": .string(field)]))
        case .addToSet(let key, let field):
            return (key, .document(["$addToSet": .string(field)]))
        case .sumIf(let key, let condition, let equals, let then, let elseMultiply):
            return (key, .document([
                "$sum": .document([
                    "$cond": .array([
                        .document(["$eq": .array([.string(condition), .string(equals)])]),
                        .string(then),
                        .document(["$multiply": .array([.string(then), .int32(Int32(elseMultiply))])])
                    ])
                ])
            ]))
        }
    }
}

// MARK: - Chainable Group Builder

class GroupBuilder {
    private var fields: [AggField] = []
    private let groupBy: BSON
    
    init(by field: String) {
        self.groupBy = .string(field)
    }
    
    init(by field: BSON) {
        self.groupBy = field
    }
    
    @discardableResult
    func first(_ key: String, field: String) -> Self {
        fields.append(.first(key, field: field))
        return self
    }
    
    @discardableResult
    func last(_ key: String, field: String) -> Self {
        fields.append(.last(key, field: field))
        return self
    }
    
    @discardableResult
    func sum(_ key: String, field: String) -> Self {
        fields.append(.sum(key, field: field))
        return self
    }
    
    @discardableResult
    func avg(_ key: String, field: String) -> Self {
        fields.append(.avg(key, field: field))
        return self
    }
    
    @discardableResult
    func min(_ key: String, field: String) -> Self {
        fields.append(.min(key, field: field))
        return self
    }
    
    @discardableResult
    func max(_ key: String, field: String) -> Self {
        fields.append(.max(key, field: field))
        return self
    }
    
    @discardableResult
    func count(_ key: String) -> Self {
        fields.append(.count(key))
        return self
    }
    
    @discardableResult
    func push(_ key: String, field: String) -> Self {
        fields.append(.push(key, field: field))
        return self
    }
    
    @discardableResult
    func addToSet(_ key: String, field: String) -> Self {
        fields.append(.addToSet(key, field: field))
        return self
    }
    
    @discardableResult
    func sumIf(_ key: String, condition: String, equals: String, then: String, elseMultiply: Int) -> Self {
        fields.append(.sumIf(key, condition: condition, equals: equals, then: then, elseMultiply: elseMultiply))
        return self
    }
    
    func buildDocument() -> BSONDocument {
        var doc: BSONDocument = ["_id": groupBy]
        for field in fields {
            let (key, value) = field.keyValue
            doc[key] = value
        }
        return doc
    }
}

