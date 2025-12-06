//
//  PaginationBuilder.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 07/12/25.
//

import SwiftBSON

// MARK: - Pagination Builder
class PaginationBuilder {
    private let pageNo: Int
    private let limit: Int
    private var totalCountField: String = "totalCount"
    private var includeNextPage: Bool = true
    private var includePrevPage: Bool = false
    private var includeTotalPages: Bool = true
    private var includeHasMore: Bool = false
    
    init(page: Int, limit: Int) {
        self.pageNo = page
        self.limit = limit
    }
    
    @discardableResult
    func setTotalCountField(_ field: String) -> Self {
        self.totalCountField = field
        return self
    }
    
    @discardableResult
    func withNextPage(_ include: Bool = true) -> Self {
        self.includeNextPage = include
        return self
    }
    
    @discardableResult
    func withPrevPage(_ include: Bool = true) -> Self {
        self.includePrevPage = include
        return self
    }
    
    @discardableResult
    func withTotalPages(_ include: Bool = true) -> Self {
        self.includeTotalPages = include
        return self
    }
    
    @discardableResult
    func withHasMore(_ include: Bool = true) -> Self {
        self.includeHasMore = include
        return self
    }
    
    // Get skip count
    func getSkip() -> Int {
        return (pageNo - 1) * limit
    }
    
    // Get limit
    func getLimit() -> Int {
        return limit
    }
    
    // Get page number
    func getPage() -> Int {
        return pageNo
    }
    
    // Build pagination document for project stage
    func buildPaginationDocument(metadataPath: String = "$metadata.totalCount") -> BSONDocument {
        var paginationDoc: BSONDocument = [
            "currentPage": .int32(Int32(pageNo)),
            "limit": .int32(Int32(limit)),
            "totalCount": .document([
                "$ifNull": .array([
                    .document([
                        "$arrayElemAt": .array([.string(metadataPath), .int32(0)])
                    ]),
                    .int32(0)
                ])
            ])
        ]
        
        if includeTotalPages {
            paginationDoc["totalPages"] = .document([
                "$ceil": .array([
                    .document([
                        "$divide": .array([
                            .document([
                                "$ifNull": .array([
                                    .document([
                                        "$arrayElemAt": .array([.string(metadataPath), .int32(0)])
                                    ]),
                                    .int32(0)
                                ])
                            ]),
                            .int32(Int32(limit))
                        ])
                    ])
                ])
            ])
        }
        
        if includeNextPage {
            paginationDoc["nextPage"] = .document([
                "$cond": .array([
                    .document([
                        "$lt": .array([
                            .int32(Int32(pageNo)),
                            .document([
                                "$ceil": .array([
                                    .document([
                                        "$divide": .array([
                                            .document([
                                                "$ifNull": .array([
                                                    .document([
                                                        "$arrayElemAt": .array([.string(metadataPath), .int32(0)])
                                                    ]),
                                                    .int32(0)
                                                ])
                                            ]),
                                            .int32(Int32(limit))
                                        ])
                                    ])
                                ])
                            ])
                        ])
                    ]),
                    .document(["$add": .array([.int32(Int32(pageNo)), .int32(1)])]),
                    BSON.null
                ])
            ])
        }
        
        if includePrevPage {
            paginationDoc["prevPage"] = .document([
                "$cond": .array([
                    .document([
                        "$gt": .array([.int32(Int32(pageNo)), .int32(1)])
                    ]),
                    .document(["$subtract": .array([.int32(Int32(pageNo)), .int32(1)])]),
                    BSON.null
                ])
            ])
        }
        
        if includeHasMore {
            paginationDoc["hasMore"] = .document([
                "$lt": .array([
                    .int32(Int32(pageNo)),
                    .document([
                        "$ceil": .array([
                            .document([
                                "$divide": .array([
                                    .document([
                                        "$ifNull": .array([
                                            .document([
                                                "$arrayElemAt": .array([.string(metadataPath), .int32(0)])
                                            ]),
                                            .int32(0)
                                        ])
                                    ]),
                                    .int32(Int32(limit))
                                ])
                            ])
                        ])
                    ])
                ])
            ])
        }
        return paginationDoc
    }
}
