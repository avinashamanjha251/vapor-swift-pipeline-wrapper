//
//  AggregationBuilder.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 06/12/25.
//

import Foundation
import SwiftBSON

// MARK: - AggregationStage Enum
enum AggregationStage {
    case match(BSONDocument)
    case matchField(key: String, value: BSON)
    case matchFieldIn(key: String, values: [String])
    case matchFieldInObjectIds(key: String, values: [String])
    case matchDateRange(key: String, dateRange: DateRange)
    case matchNumberRange(key: String, min: Double?, max: Double?)
    case matchGreaterThan(key: String, value: Double)
    case matchLessThan(key: String, value: Double)
    case matchExists(key: String, exists: Bool)
    case matchRegex(key: String, pattern: String, options: String?)
    case group(id: BSON, fields: BSONDocument)
    case groupBuilder(GroupBuilder)
    case project(BSONDocument)
    case projectBuilder(ProjectBuilder)
    case projectFields(include: [String]?, exclude: [String]?, computed: BSONDocument?)
    case sort(BSONDocument)
    case sortField(key: String, ascending: Bool)
    case sortByType(String?, amountKey: String, dateKey: String)
    case limit(Int)
    case skip(Int)
    case lookup(from: String, localField: String, foreignField: String, as: String)
    case unwind(String, preserveNull: Bool)
    case facet([String: [AggregationStage]])
    case facetBuilder(FacetBuilder)
    case addFields(BSONDocument)
    case count(String)
    case sample(Int)
    case unset([String])
    
    var bson: BSONDocument {
        switch self {
        case .match(let filters):
            return ["$match": .document(filters)]
            
        case .matchField(let key, let value):
            return ["$match": .document([key: value])]
            
        case .matchFieldIn(let key, let values):
            guard !values.isEmpty else { return [:] }
            return ["$match": .document([
                key: .document([
                    "$in": .array(values.map { .string($0) })
                ])
            ])]
            
        case .matchFieldInObjectIds(let key, let values):
            guard !values.isEmpty else { return [:] }
            let objectIds = values.compactMap { try? BSONObjectID($0) }
            guard !objectIds.isEmpty else { return [:] }
            return ["$match": .document([
                key: .document([
                    "$in": .array(objectIds.map { .objectID($0) })
                ])
            ])]
            
        case .matchDateRange(let key, let dateRange):
            return ["$match": .document([
                key: .document([
                    "$gte": .double(dateRange.start),
                    "$lte": .double(dateRange.end)
                ])
            ])]
            
        case .matchNumberRange(let key, let min, let max):
            var filter: BSONDocument = [:]
            if let min = min {
                filter["$gte"] = .double(min)
            }
            if let max = max {
                filter["$lte"] = .double(max)
            }
            guard !filter.isEmpty else { return [:] }
            return ["$match": .document([key: .document(filter)])]
            
        case .matchGreaterThan(let key, let value):
            return ["$match": .document([
                key: .document(["$gt": .double(value)])
            ])]
            
        case .matchLessThan(let key, let value):
            return ["$match": .document([
                key: .document(["$lt": .double(value)])
            ])]
            
        case .matchExists(let key, let exists):
            return ["$match": .document([
                key: .document(["$exists": .bool(exists)])
            ])]
            
        case .matchRegex(let key, let pattern, let options):
            var regexDoc: BSONDocument = [
                "$regex": .string(pattern)
            ]
            if let options = options {
                regexDoc["$options"] = .string(options)
            }
            return ["$match": .document([key: .document(regexDoc)])]
            
        case .group(let id, let fields):
            var doc = fields
            doc["_id"] = id
            return ["$group": .document(doc)]
            
        case .groupBuilder(let builder):
            let doc = builder.buildDocument()
            return ["$group": .document(doc)]
            
        case .project(let fields):
            return ["$project": .document(fields)]
            
        case .projectBuilder(let builder):
            let doc = builder.buildDocument()
            return ["$project": .document(doc)]
            
        case .projectFields(let include, let exclude, let computed):
            var fields: BSONDocument = [:]
            
            if let include = include {
                for field in include {
                    fields[field] = .int32(1)
                }
            }
            
            if let exclude = exclude {
                for field in exclude {
                    fields[field] = .int32(0)
                }
            }
            
            if let computed = computed {
                for (key, value) in computed {
                    fields[key] = value
                }
            }
            
            return ["$project": .document(fields)]
            
        case .sort(let sortBy):
            return ["$sort": .document(sortBy)]
            
        case .sortField(let key, let ascending):
            return ["$sort": .document([key: .int32(ascending ? 1 : -1)])]
            
        case .sortByType(let sortBy, let amountKey, let dateKey):
            let sortBy = sortBy ?? "NEWEST"
            var sortDoc: BSONDocument
            
            switch sortBy {
            case "HIGHEST":
                sortDoc = [amountKey: .int32(-1)]
            case "LOWEST":
                sortDoc = [amountKey: .int32(1)]
            case "NEWEST":
                sortDoc = [dateKey: .int32(-1)]
            case "OLDEST":
                sortDoc = [dateKey: .int32(1)]
            default:
                sortDoc = [dateKey: .int32(-1)]
            }
            
            return ["$sort": .document(sortDoc)]
            
        case .limit(let count):
            return ["$limit": .int64(Int64(count))]
            
        case .skip(let count):
            return ["$skip": .int64(Int64(count))]
            
        case .lookup(let from, let local, let foreign, let asField):
            return ["$lookup": .document([
                "from": .string(from),
                "localField": .string(local),
                "foreignField": .string(foreign),
                "as": .string(asField)
            ])]
            
        case .unwind(let path, let preserveNull):
            if preserveNull {
                return ["$unwind": .document([
                    "path": .string(path),
                    "preserveNullAndEmptyArrays": .bool(true)
                ])]
            }
            return ["$unwind": .string(path)]
            
        case .facet(let facets):
            var doc: BSONDocument = [:]
            for (key, stages) in facets {
                doc[key] = .array(stages.map { .document($0.bson) })
            }
            return ["$facet": .document(doc)]
            
        case .facetBuilder(let builder):
            var doc: BSONDocument = [:]
            let facets = builder.buildFacets()
            for (key, stages) in facets {
                doc[key] = .array(stages.map { .document($0.bson) })
            }
            return ["$facet": .document(doc)]
            
        case .addFields(let fields):
            return ["$addFields": .document(fields)]
            
        case .count(let name):
            return ["$count": .string(name)]
            
        case .sample(let size):
            return ["$sample": .document(["size": .int32(Int32(size))])]
            
        case .unset(let fields):
            if fields.count == 1 {
                return ["$unset": .string(fields[0])]
            }
            return ["$unset": .array(fields.map { .string($0) })]
        }
    }
}
