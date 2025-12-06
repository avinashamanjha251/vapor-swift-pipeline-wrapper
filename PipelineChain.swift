//
//  PipelineChain.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 06/12/25.
//

import Vapor
import MongoDBVapor

// MARK: - Chainable Pipeline Builder
class PipelineChain: @unchecked Sendable {
    private var stages: [AggregationStage] = []
    
    init() {}
    
    private init(stages: [AggregationStage]) {
        self.stages = stages
    }
    
    // MARK: - Match
    @discardableResult
    func match(_ filters: BSONDocument) -> Self {
        stages.append(.match(filters))
        return self
    }
    
    @discardableResult
    func match(userId: String, status: String? = nil) -> Self {
        var filters: BSONDocument = ["userId": .string(userId)]
        if let status = status {
            filters["status"] = .string(status)
        }
        stages.append(.match(filters))
        return self
    }
    
    // MARK: - Sort
    @discardableResult
    func sort(_ field: String, ascending: Bool = true) -> Self {
        stages.append(.sort([field: .int32(ascending ? 1 : -1)]))
        return self
    }
    
    @discardableResult
    func sort(_ fields: BSONDocument) -> Self {
        stages.append(.sort(fields))
        return self
    }
    
    // MARK: - Limit & Skip
    @discardableResult
    func limit(_ count: Int) -> Self {
        stages.append(.limit(count))
        return self
    }
    
    @discardableResult
    func skip(_ count: Int) -> Self {
        stages.append(.skip(count))
        return self
    }
    
    @discardableResult
    func paginate(page: Int, limit: Int) -> Self {
        stages.append(.skip((page - 1) * limit))
        stages.append(.limit(limit))
        return self
    }
    
    // MARK: - Lookup & Unwind
    @discardableResult
    func lookup(from: String,
                localField: String,
                foreignField: String,
                as asStr: String) -> Self {
        stages.append(.lookup(from: from,
                              localField: localField,
                              foreignField: foreignField,
                              as: asStr))
        return self
    }
    
    @discardableResult
    func unwind(_ path: String,
                preserveNull: Bool = false) -> Self {
        stages.append(.unwind(path,
                              preserveNull: preserveNull))
        return self
    }
    
    // MARK: - Other Stages
    @discardableResult
    func addFields(_ fields: BSONDocument) -> Self {
        stages.append(.addFields(fields))
        return self
    }
    
    @discardableResult
    func count(as name: String = "count") -> Self {
        stages.append(.count(name))
        return self
    }
    
    @discardableResult
    func sample(size: Int) -> Self {
        stages.append(.sample(size))
        return self
    }
    
    @discardableResult
    func unset(_ fields: [String]) -> Self {
        stages.append(.unset(fields))
        return self
    }
    
    @discardableResult
    func addStage(_ stage: AggregationStage) -> Self {
        stages.append(stage)
        return self
    }
    
    // MARK: - Getters
    func getStages() -> [AggregationStage] {
        return stages
    }
    
    func build() -> [BSONDocument] {
        return stages.map { $0.bson }
    }
}

// MARK: - Enhanced Group
extension PipelineChain {
    
    @discardableResult
    func group(by field: String, _ configure: (GroupBuilder) -> Void) -> Self {
        let builder = GroupBuilder(by: field)
        configure(builder)
        let doc = builder.buildDocument()
        if let id = doc["_id"] {
            stages.append(AggregationStage.group(id: id, fields: doc))
        }
        return self
    }
    
    @discardableResult
    func group(by field: BSON, _ configure: (GroupBuilder) -> Void) -> Self {
        let builder = GroupBuilder(by: field)
        configure(builder)
        let doc = builder.buildDocument()
        if let id = doc["_id"] {
            stages.append(AggregationStage.group(id: id, fields: doc))
        }
        return self
    }
}

// MARK: - Updated PipelineChain Facet Methods

extension PipelineChain {
    
    // Method 1: Closure-based (new)
    @discardableResult
    func facet(_ configure: (FacetBuilder) -> Void) -> Self {
        let builder = FacetBuilder()
        configure(builder)
        stages.append(.facetBuilder(builder))
        return self
    }
    
    // Method 2: Direct dictionary with stages (existing)
    @discardableResult
    func facet(_ facets: [String: [AggregationStage]]) -> Self {
        stages.append(.facet(facets))
        return self
    }
    
    // Method 3: Dictionary with PipelineChain (existing)
    @discardableResult
    func facet(_ facets: [String: PipelineChain]) -> Self {
        let converted = facets.mapValues { $0.getStages() }
        stages.append(.facet(converted))
        return self
    }
    
    // Method 4: Add pre-built FacetBuilder
    @discardableResult
    func addFacet(_ builder: FacetBuilder) -> Self {
        stages.append(.facetBuilder(builder))
        return self
    }
}

// MARK: - Updated PipelineChain Project Methods
extension PipelineChain {
    // Raw project (existing)
    @discardableResult
    func project(_ fields: BSONDocument) -> Self {
        stages.append(.project(fields))
        return self
    }
    
    // Include only (existing)
    @discardableResult
    func project(include: [String]) -> Self {
        stages.append(.projectFields(include: include,
                                     exclude: nil,
                                     computed: nil))
        return self
    }
    
    // Exclude only (existing)
    @discardableResult
    func project(exclude: [String]) -> Self {
        stages.append(.projectFields(include: nil,
                                     exclude: exclude, computed: nil))
        return self
    }
    
    // Mixed (existing)
    @discardableResult
    func project(include: [String]? = nil,
                 exclude: [String]? = nil,
                 computed: BSONDocument? = nil) -> Self {
        stages.append(.projectFields(include: include,
                                     exclude: exclude,
                                     computed: computed))
        return self
    }
    
    // NEW: Builder-based project
    @discardableResult
    func project(_ configure: (ProjectBuilder) -> Void) -> Self {
        let builder = ProjectBuilder()
        configure(builder)
        stages.append(.projectBuilder(builder))
        return self
    }
    
    // NEW: Add pre-built ProjectBuilder
    @discardableResult
    func addProject(_ builder: ProjectBuilder) -> Self {
        stages.append(.projectBuilder(builder))
        return self
    }
}

// MARK: - Extension to MongoCRUD Protocol
extension MongoCRUD {
    
    /// Execute pipeline chain and return JSONArray
    func executePipeline(_ chain: PipelineChain,
                         ignoring ignoredKeys: [String] = []) async throws -> JSONArray {
        let pipeline = chain.build()
        return try await aggregatePipeline(pipeline,
                                           ignoring: ignoredKeys)
    }
    
    /// Execute pipeline chain and return raw BSONDocuments
    func executePipelineRaw(_ chain: PipelineChain) async throws -> [BSONDocument] {
        let pipeline = chain.build()
        return try await sumAggregatePipeline(pipeline)
    }
    
    /// Execute pipeline chain and decode to models
    func executePipeline<T: Codable>(_ chain: PipelineChain,
                                     as type: T.Type) async throws -> [T] {
        let pipeline = chain.build()
        let cursor = try await collection.aggregate(pipeline)
        let documents = try await cursor.toArray()
        
        return try documents.map { doc in
            try BSONDecoder().decode(T.self, from: doc)
        }
    }
}

// MARK: - Extension to BaseMongoViewModel
extension BaseMongoViewModel {
    /// Create pipeline chain
    func pipeline() -> PipelineChain {
        return PipelineChain()
    }
}
