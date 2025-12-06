//
//  AggregationStage.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 06/12/25.
//

import SwiftBSON

// MARK: - Aggregation Stage Enum
enum AggregationStage {
    case match(BSONDocument)
    case group(id: BSON, fields: BSONDocument)
    case project(BSONDocument)
    case projectBuilder(ProjectBuilder)
    case projectFields(include: [String]?, exclude: [String]?, computed: BSONDocument?)
    case sort(BSONDocument)
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
        case .group(let id, let fields):
            var doc = fields
            doc["_id"] = id
            return ["$group": .document(doc)]
        case .project(let fields):
            return ["$project": .document(fields)]
        case .projectBuilder(let builder):
            let doc = builder.buildDocument()
            return ["$project": .document(doc)]
        case .projectFields(let include, let exclude, let computed):
            var fields: BSONDocument = [:]
            // Add included fields
            if let include = include {
                for field in include {
                    fields[field] = .int32(1)
                }
            }
            // Add excluded fields
            if let exclude = exclude {
                for field in exclude {
                    fields[field] = .int32(0)
                }
            }
            // Add computed fields
            if let computed = computed {
                for (key, value) in computed {
                    fields[key] = value
                }
            }
            return ["$project": .document(fields)]
        case .sort(let sortBy):
            return ["$sort": .document(sortBy)]
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
