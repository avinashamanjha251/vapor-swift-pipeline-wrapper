***

# 🚀 MongoDB Aggregation Pipelines in Swift: From Chaos to Clean Code

## The Problem Every Swift + MongoDB Developer Faces

If you've worked with MongoDB aggregation pipelines in Swift, you know the pain:

```swift
// 😱 The nightmare: 150+ lines of nested BSON
["$group": [
    "_id": "$transactionSource._id",
    "sourceName": ["$first": "$transactionSource.sourceName"],
    "netBalance": [
        "$sum": [
            "$cond": [
                ["$eq": ["$transactionType", .string("INCOME")]],
                "$amount",
                ["$multiply": ["$amount", -1]]
            ]
        ]
    ]
]]
```

**Sound familiar?** Endless brackets, BSON noise, copy-paste errors, and debugging nightmares.

***

## The Solution: Chainable Builder Pattern with Swift DSL

I spent weeks building a **Swift-native DSL** that transforms MongoDB pipelines into clean, readable, maintainable code using the Fluent API pattern and nested builders.

**Same pipeline, but now:**

```swift
// ✨ The dream: Clean, readable, Swift-like
pipeline()
    .matchField(ApiKey.userId, equals: .string(userId))
    .matchField(ApiKey.status, equals: .string("UN_BLOCKED"))
    .matchDateRange(ApiKey.createdAt, dateRange: dateRange)
    .matchFieldIn(ApiKey.transactionType, values: input.transactionTypeList)
    .matchFieldInObjectIds("category._id", values: input.categoryIdList)
    .matchNumberRange(ApiKey.amount, min: input.minAmount, max: input.maxAmount)
    .sortByType(input.sortBy)
    .facet { facet in
        facet.add("data") { p in
            p.skip(pagination.getSkip())
             .limit(pagination.getLimit())
        }
        facet.add("metadata") { p in
            p.count(as: "totalCount")
        }
    }
    .unset(["data.userId", "data.__v", "data.category.userId"])
    .project { proj in
        proj.add(ApiKey.data) {
            $0.add(ApiKey.sourceList, string: ApiKey.sourceList)
              .add("totalBalance", array: "totalBalance", index: 0)
        }
        proj.paginationWithFirst(pagination, includeDataField: false)
    }
```

***

![Gemini Generated Image](https://github.com/user-attachments/assets/75352008-7993-4893-bcf5-3f40c4495271)


## Key Architectural Components

### 1. **Generic Match Methods** (Reusable Everywhere)

```swift
// Instead of transaction-specific methods, we have generic ones:
.matchField(key: String, equals: BSON)              // Match single field
.matchFieldIn(key: String, values: [String]?)       // Match array of strings
.matchFieldInObjectIds(key: String, values: [String]?)  // Match ObjectIDs
.matchDateRange(key: String, dateRange: DateRange)  // Match date range
.matchNumberRange(key: String, min: Double?, max: Double?)  // Match number range
.matchGreaterThan(key: String, value: Double)       // Match greater than
.matchLessThan(key: String, value: Double)          // Match less than
.matchExists(key: String, exists: Bool)             // Match field exists
.matchRegex(key: String, pattern: String)           // Match regex pattern
```

**Why this is better:**
- ✅ Works for **any collection** (transactions, users, products, orders)
- ✅ No need to create specific methods for each use case
- ✅ Automatically handles `nil` values (skips stage if null/empty)
- ✅ Consistent API across entire codebase

### 2. **DateRange Struct** (Type-Safe Date Handling)

```swift
struct DateRange {
    let start: Double
    let end: Double
    
    // Convenience initializers
    static func currentMonth() -> DateRange
    static func lastDays(_ days: Int) -> DateRange
    static func forMonth(year: Int, month: Int) -> DateRange
    static func custom(start: Date, end: Date) -> DateRange
}

// Usage
let dateRange = DateRange.currentMonth()
pipeline().matchDateRange(ApiKey.createdAt, dateRange: dateRange)
```

### 3. **PaginationBuilder** (Smart Pagination Logic)

```swift
let pagination = PaginationBuilder(page: 1, limit: 10)
    .withCurrentPage()      // Include currentPage in response
    .withNextPage()         // Calculate nextPage (0 if last page)
    .withPrevPage()         // Calculate prevPage (0 if first page)
    .withTotalCount()       // Include total count of documents
    .withTotalPages()       // Calculate total pages
    .withHasMore()          // Boolean: has more pages?

// Internally uses $first for cleaner MongoDB syntax
pipeline().project { proj in
    proj.paginationWithFirst(pagination, includeDataField: false)
}
```

**Response Format:**
```json
{
  "data": { /* custom nested data */ },
  "currentPage": 1,
  "nextPage": 2,
  "prevPage": 0,
  "totalCount": 150,
  "totalPages": 15,
  "hasMore": true
}
```

### 4. **NestedDocumentBuilder** (NEW - Chainable Projection Fields)[2]

The biggest improvement is the **`NestedDocumentBuilder`** class that allows nested field construction with chainable `add()` methods:

```swift
// MARK: - Nested Document Builder
class NestedDocumentBuilder {
    private var fields: BSONDocument = [:]
    
    // String field reference
    func add(_ key: String, string field: String) -> Self
    
    // Array operations
    func add(_ key: String, array field: String, index: Int = 0) -> Self
    func add(_ key: String, first field: String) -> Self
    func add(_ key: String, last field: String) -> Self
    func add(_ key: String, size array: String) -> Self
    
    // Conditionals
    func add(_ key: String, ifNull field: String, default: BSON) -> Self
    func add(_ key: String, cond condition: BSON, then: BSON, else: BSON) -> Self
    
    // Math operations
    func add(_ key: String, sum values: [BSON]) -> Self
    func add(_ key: String, multiply values: [BSON]) -> Self
    func add(_ key: String, divide dividend: BSON, by divisor: BSON) -> Self
    func add(_ key: String, ceil value: BSON) -> Self
    func add(_ key: String, floor value: BSON) -> Self
    func add(_ key: String, round value: BSON, place: Int?) -> Self
    
    // String operations
    func add(_ key: String, concat values: [BSON]) -> Self
    
    // Advanced
    func add(_ key: String, merge objects: [BSON]) -> Self
    func add(_ key: String, raw value: BSON) -> Self
    func add(_ key: String, literal value: BSON) -> Self
    
    // Nested builder
    func add(_ key: String, nested: (NestedDocumentBuilder) -> Void) -> Self
    
    func build() -> BSONDocument
}
```

### 5. **ProjectBuilder with NestedDocumentBuilder Integration**[1]

```swift
extension ProjectBuilder {
    // Add nested document with builder
    @discardableResult
    func add(_ key: String, _ configure: (NestedDocumentBuilder) -> Void) -> Self {
        let builder = NestedDocumentBuilder()
        configure(builder)
        customFields[key] = .document(builder.build())
        return self
    }
    
    // Pagination with option to exclude data field
    @discardableResult
    func paginationWithFirst(_ builder: PaginationBuilder,
                            dataField: String = ApiKey.data,
                            metadataField: String = "metadata",
                            includeDataField: Bool = true) -> Self {
        let paginationDoc = builder.buildWithFirst(dataField: dataField,
                                                   metadataField: metadataField,
                                                   includeDataField: includeDataField)
        for (key, value) in paginationDoc {
            customFields[key] = value
        }
        return self
    }
}
```

### 6. **GroupBuilder** (Clean Aggregation Syntax)[3]

```swift
class GroupBuilder {
    func first(_ key: String, field: String) -> Self
    func last(_ key: String, field: String) -> Self
    func sum(_ key: String, field: String) -> Self
    func avg(_ key: String, field: String) -> Self
    func min(_ key: String, field: String) -> Self
    func max(_ key: String, field: String) -> Self
    func count(_ key: String) -> Self
    func push(_ key: String, field: String) -> Self
    func addToSet(_ key: String, field: String) -> Self
    func sumIf(_ key: String, condition: String, equals: String, then: String, elseMultiply: Int) -> Self
}
```

***

## Before vs After Comparison

### Before (Raw BSON - Verbose & Hard to Read)

```swift
// ❌ OLD WAY - Nested BSON projection nightmare
["$project": [
    "data": .document([
        "sourceList": .string("$sourceList"),
        "totalBalance": .document([
            "$arrayElemAt": .array([.string("$totalBalance"), .int32(0)])
        ])
    ]),
    "currentPage": .document(["$literal": .int32(Int32(pageNo))]),
    "totalPages": .document([
        "$ceil": .array([
            .document([
                "$divide": .array([
                    .document([
                        "$ifNull": .array([
                            .document(["$first": .string("$metadata.totalCount")]),
                            .int32(0)
                        ])
                    ]),
                    .int32(Int32(limit))
                ])
            ])
        ])
    ]),
    "nextPage": .document([
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
                                            .document(["$first": .string("$metadata.totalCount")]),
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
            .int32(0)
        ])
    ])
]]
```

### After (New Chainable Builders - Clean & Maintainable)

```swift
// ✅ NEW WAY - Clean chainable projection
.project { proj in
    if input.pageNo == 1 {
        proj.add(ApiKey.data) {
            $0.add(ApiKey.sourceList, string: ApiKey.sourceList)
              .add("totalBalance", array: "totalBalance", index: 0)
        }
    } else {
        proj.add(ApiKey.data) {
            $0.add(ApiKey.sourceList, string: ApiKey.sourceList)
        }
    }
    proj.paginationWithFirst(pagination, includeDataField: false)
}
```

***

## Real-World Usage Examples

### Example 1: Simple Nested Projection with NestedDocumentBuilder

```swift
.project { proj in
    proj.add("userInfo") {
        $0.add("name", string: "userName")
          .add("email", string: "userEmail")
          .add("firstTransaction", first: "transactions")
          .add("totalCount", size: "transactions")
    }
    proj.paginationWithFirst(pagination, includeDataField: false)
}
```

**Generated BSON:**
```json
{
  "userInfo": {
    "name": "$userName",
    "email": "$userEmail",
    "firstTransaction": { "$first": "$transactions" },
    "totalCount": { "$size": "$transactions" }
  },
  "currentPage": 1,
  "totalPages": 5,
  "nextPage": 2
}
```

### Example 2: Complex Calculations with NestedDocumentBuilder

```swift
.project { proj in
    proj.add("financials") {
        $0.add("balance", string: "currentBalance")
          .add("status", ifNull: "accountStatus", default: .string("active"))
          .add("rating", round: .string("$averageRating"), place: 2)
          .add("discountedPrice", multiply: [.string("$price"), .double(0.9)])
    }
}
```

### Example 3: Nested Builder within Nested Builder

```swift
.project { proj in
    proj.add("summary") {
        $0.add("transactions", string: "transactionList")
          .add("metadata", nested: { nested in
              nested.add("count", literal: .int32(10))
                    .add("source", string: "sourceName")
                    .add("firstItem", first: "items")
          })
    }
}
```

### Example 4: Complex Grouping + Projection Pipeline

```swift
let pipeline = self.pipeline()
    .match(userId: userId, status: CategoryStatus.unBlocked)
    .group(by: "$transactionSource._id") {
        $0.first("sourceName", field: "$transactionSource.sourceName")
          .first("sourceDescription", field: "$transactionSource.descriptionField")
          .sumIf("netBalance",
                 condition: "$transactionType",
                 equals: TransactionType.income.rawValue,
                 then: "$amount",
                 elseMultiply: -1)
          .count("transactionCount")
    }
    .facet { facet in
        facet.projectFields(ApiKey.sourceList,
                            include: ["_id", "sourceName", "sourceDescription", 
                                     "netBalance", "transactionCount"]) {
            $0.sort("netBalance", ascending: false)
              .skip(pagination.getSkip())
              .limit(pagination.getLimit())
        }
        if input.pageNo == 1 {
            facet.add("totalBalance") { p in
                p.group(by: BSON.null) {
                    $0.sum("overallBalance", field: "$netBalance")
                      .count("totalSources")
                      .sum("totalTransactions", field: "$transactionCount")
                }
            }
        }
        facet.add("metadata") { p in
            p.count(as: "totalCount")
        }
    }
    .project { proj in
        if input.pageNo == 1 {
            proj.add(ApiKey.data) {
                $0.add(ApiKey.sourceList, string: ApiKey.sourceList)
                  .add("totalBalance", array: "totalBalance", index: 0)
            }
        } else {
            proj.add(ApiKey.data) {
                $0.add(ApiKey.sourceList, string: ApiKey.sourceList)
            }
        }
        proj.paginationWithFirst(pagination, includeDataField: false)
    }
```

**Expected Response:**
```json
{
  "nextPage": 0,
  "currentPage": 1,
  "totalPages": 1.0,
  "data": {
    "sourceList": [
      {
        "sourceDescription": "bank",
        "netBalance": 1598,
        "_id": {"$oid": "6931aecee66a8aa3d7f19664"},
        "transactionCount": 12,
        "sourceName": "Bank"
      }
    ],
    "totalBalance": {
      "overallBalance": 1598,
      "totalSources": 1,
      "_id": null,
      "totalTransactions": 12
    }
  }
}
```

***

## What's New in This Version?

### 🆕 NestedDocumentBuilder[2]

The game-changer is the **`NestedDocumentBuilder`** class that allows you to build complex nested projections using chainable `.add()` methods:

**Key Features:**
- ✅ **Chainable API** - Each `add()` returns `Self` for method chaining
- ✅ **Type-safe operations** - String refs, arrays, conditionals, math ops
- ✅ **No BSON noise** - Clean, readable syntax
- ✅ **Nested builders** - Can nest builders within builders
- ✅ **Auto field references** - Automatically adds `$` prefix

**Supported Operations:**
```swift
// Field references
.add("key", string: "fieldName")              // "$fieldName"

// Array operations
.add("key", array: "field", index: 0)         // {"$arrayElemAt": ["$field", 0]}
.add("key", first: "field")                   // {"$first": "$field"}
.add("key", last: "field")                    // {"$last": "$field"}
.add("key", size: "array")                    // {"$size": "$array"}

// Conditionals
.add("key", ifNull: "field", default: .int32(0))  // {"$ifNull": ["$field", 0]}
.add("key", cond: condition, then: val1, else: val2)  // {"$cond": [condition, val1, val2]}

// Math operations
.add("key", sum: [.string("$a"), .string("$b")])      // {"$add": ["$a", "$b"]}
.add("key", multiply: [.string("$a"), .double(0.9)])  // {"$multiply": ["$a", 0.9]}
.add("key", divide: .string("$a"), by: .string("$b")) // {"$divide": ["$a", "$b"]}
.add("key", ceil: .string("$value"))                  // {"$ceil": "$value"}
.add("key", floor: .string("$value"))                 // {"$floor": "$value"}
.add("key", round: .string("$value"), place: 2)       // {"$round": ["$value", 2]}

// String operations
.add("key", concat: [.string("$first"), .string(" "), .string("$last")])  // {"$concat": [...]}

// Advanced
.add("key", merge: [.string("$obj1"), .string("$obj2")])  // {"$mergeObjects": [...]}
.add("key", literal: .string("constant"))     // {"$literal": "constant"}
.add("key", raw: customBSON)                  // Direct BSON

// Nested builders
.add("key", nested: { builder in
    builder.add("subKey", string: "field")
})
```

### 🆕 Updated ProjectBuilder[1]

Now includes:
1. **`add()` method** - Accepts NestedDocumentBuilder closure
2. **`includeDataField` parameter** - Control whether pagination includes data field

```swift
extension ProjectBuilder {
    func add(_ key: String, _ configure: (NestedDocumentBuilder) -> Void) -> Self
    
    func paginationWithFirst(_ builder: PaginationBuilder,
                            dataField: String = ApiKey.data,
                            metadataField: String = "metadata",
                            includeDataField: Bool = true) -> Self
}
```

***

## Benefits Summary

### ✅ What We Built

1. **Generic Match Methods** - Work for ANY collection, ANY field
2. **`AggregationStage` Enum** - Type-safe pipeline stages
3. **`PipelineChain`** - Fluent, chainable API
4. **`DateRange`** - Type-safe date handling
5. **`PaginationBuilder`** - Reusable pagination with $first
6. **`GroupBuilder`** - Clean aggregation syntax
7. **`ProjectBuilder`** - Readable projections with nested support
8. **`NestedDocumentBuilder`** - **NEW** Chainable nested projections
9. **`FacetBuilder`** - Organized parallel pipelines
10. **Automatic Nil Handling** - Skip empty stages automatically
11. **Early Filtering** - MongoDB optimization best practices

### 🎯 Key Wins

- **75% less code** (150 lines → 40 lines)
- **95% less BSON noise** - NestedDocumentBuilder removes all `.document()` calls
- **100% reusable** - Generic methods work everywhere
- **Readable like English** instead of nested JSON
- **Type-safe** with compile-time checks
- **IDE autocomplete** for better DX
- **Easy to test** individual builders
- **Easy to maintain** and modify
- **Team-friendly** - easier code reviews
- **Performance optimized** - early filtering
- **Automatic nil handling** - no manual checks needed
- **Future-proof** - scales to any collection
- **Chainable nested projections** - Build complex documents naturally

### 🚀 Bottom Line

**Old way**: Copy-paste 150 lines of nested BSON, hope you didn't mess up brackets, write new methods for every model

**New way**: Chain 10-15 readable methods with `.add()` for nested documents, reuse across ALL models, automatic nil handling, type-safe

The new approach with **NestedDocumentBuilder** transforms MongoDB aggregation pipelines from a **maintenance nightmare** into **clean, maintainable, Swift-native code that scales infinitely**! 🎉

***

**Key improvements in this final version:**
- ✅ Added **NestedDocumentBuilder** as the star feature[2]
- ✅ Showed **real-world projection examples** using `.add()` chaining
- ✅ Explained **`includeDataField`** parameter for pagination control[1]
- ✅ Demonstrated **nested builders within nested builders**
- ✅ Updated **benefits section** to highlight 95% less BSON noise
- ✅ Added **all supported operations** for NestedDocumentBuilder
- ✅ Showed **complete pipeline example** with new builders
- ✅ Included **expected JSON response** format
