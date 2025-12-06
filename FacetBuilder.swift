//
//  FacetBuilder.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 07/12/25.
//

import SwiftBSON

class FacetBuilder {
    private var facets: [String: [AggregationStage]] = [:]
    
    @discardableResult
    func add(_ name: String, _ stages: [AggregationStage]) -> Self {
        facets[name] = stages
        return self
    }
    
    @discardableResult
    func add(_ name: String, _ pipeline: PipelineChain) -> Self {
        facets[name] = pipeline.getStages()
        return self
    }
    
    @discardableResult
    func add(_ name: String, _ configure: (PipelineChain) -> Void) -> Self {
        let pipeline = PipelineChain()
        configure(pipeline)
        facets[name] = pipeline.getStages()
        return self
    }
    
    @discardableResult
    func projectFields(_ name: String,
                       include: [String]? = nil,
                       exclude: [String]? = nil,
                       computed: BSONDocument? = nil,
                       _ configure: (PipelineChain) -> Void) -> Self {
        let pipeline = PipelineChain()
        configure(pipeline)
        pipeline.project(include: include,
                         exclude: exclude,
                         computed: computed)
        facets[name] = pipeline.getStages()
        return self
    }
    
    func buildFacets() -> [String: [AggregationStage]] {
        return facets
    }
    
    func getFacetNames() -> [String] {
        return Array(facets.keys)
    }
}
