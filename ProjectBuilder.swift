//
//  ProjectBuilder.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 07/12/25.
//

import SwiftBSON

// MARK: - Project Builder
class ProjectBuilder {
    private var includeFields: [String] = []
    private var excludeFields: [String] = []
    private var computedFields: BSONDocument = [:]
    private var customFields: BSONDocument = [:]
    
    // Include fields
    @discardableResult
    func include(_ fields: String...) -> Self {
        includeFields.append(contentsOf: fields)
        return self
    }
    
    @discardableResult
    func include(_ fields: [String]) -> Self {
        includeFields.append(contentsOf: fields)
        return self
    }
    
    // Exclude fields
    @discardableResult
    func exclude(_ fields: String...) -> Self {
        excludeFields.append(contentsOf: fields)
        return self
    }
    
    @discardableResult
    func exclude(_ fields: [String]) -> Self {
        excludeFields.append(contentsOf: fields)
        return self
    }
    
    // Computed fields
    @discardableResult
    func computed(_ key: String, _ value: BSON) -> Self {
        computedFields[key] = value
        return self
    }
    
    // Array element at
    @discardableResult
    func arrayElemAt(_ key: String, array: String, index: Int = 0) -> Self {
        computedFields[key] = .document([
            "$arrayElemAt": .array([.string(array), .int32(Int32(index))])
        ])
        return self
    }
    
    // Conditional field
    @discardableResult
    func conditional(_ key: String, if condition: BSONDocument, then thenVal: BSON, else elseVal: BSON) -> Self {
        computedFields[key] = .document([
            "$cond": .array([.document(condition), thenVal, elseVal])
        ])
        return self
    }
    
    // String concatenation
    @discardableResult
    func concat(_ key: String, _ parts: BSON...) -> Self {
        computedFields[key] = .document([
            "$concat": .array(parts)
        ])
        return self
    }
    
    // Math operations
    @discardableResult
    func add(_ key: String, _ values: BSON...) -> Self {
        computedFields[key] = .document([
            "$add": .array(values)
        ])
        return self
    }
    
    @discardableResult
    func multiply(_ key: String, _ values: BSON...) -> Self {
        computedFields[key] = .document([
            "$multiply": .array(values)
        ])
        return self
    }
    
    @discardableResult
    func divide(_ key: String, dividend: BSON, divisor: BSON) -> Self {
        computedFields[key] = .document([
            "$divide": .array([dividend, divisor])
        ])
        return self
    }
    
    @discardableResult
    func subtract(_ key: String, minuend: BSON, subtrahend: BSON) -> Self {
        computedFields[key] = .document([
            "$subtract": .array([minuend, subtrahend])
        ])
        return self
    }
    
    // String field reference
    @discardableResult
    func field(_ key: String, value: String) -> Self {
        customFields[key] = .string(value)
        return self
    }
    
    // Raw BSON field
    @discardableResult
    func raw(_ key: String, _ value: BSON) -> Self {
        customFields[key] = value
        return self
    }
    
    // Pagination integration
    @discardableResult
    func pagination(_ builder: PaginationBuilder, metadataPath: String = "$metadata.totalCount") -> Self {
        let paginationDoc = builder.buildPaginationDocument(metadataPath: metadataPath)
        customFields["pagination"] = .document(paginationDoc)
        return self
    }
    
    // ifNull helper
    @discardableResult
    func ifNull(_ key: String, field: BSON, default defaultValue: BSON) -> Self {
        computedFields[key] = .document([
            "$ifNull": .array([field, defaultValue])
        ])
        return self
    }
    
    // Build final document
    func buildDocument() -> BSONDocument {
        var doc: BSONDocument = [:]
        
        // Add included fields
        for field in includeFields {
            doc[field] = .int32(1)
        }
        
        // Add excluded fields
        for field in excludeFields {
            doc[field] = .int32(0)
        }
        
        // Add computed fields
        for (key, value) in computedFields {
            doc[key] = value
        }
        
        // Add custom fields
        for (key, value) in customFields {
            doc[key] = value
        }
        
        return doc
    }
}
