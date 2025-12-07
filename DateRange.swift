//
//  DateRange.swift
//  PipeLineWrapper
//
//  Created by Avinash Aman on 07/12/25.
//

import Foundation

// MARK: - DateRange Model
struct DateRange {
    let start: Double
    let end: Double
    
    init(start: Double, end: Double) {
        self.start = start
        self.end = end
    }
    
    // Create from Date objects
    init(start: Date, end: Date) {
        self.start = start.toMillis()
        self.end = end.toMillis()
    }
    
    // Create for specific month and year
    static func forMonth(year: Int, month: Int) -> DateRange {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: components) else {
            fatalError("Invalid date")
        }
        
        guard let endDate = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startDate) else {
            fatalError("Invalid end date")
        }
        
        return DateRange(start: startDate, end: endDate)
    }
    
    // Create for current month
    static func currentMonth() -> DateRange {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        
        guard let year = components.year, let month = components.month else {
            fatalError("Unable to get current month")
        }
        
        return forMonth(year: year, month: month)
    }
    
    // Create for last N days
    static func lastDays(_ days: Int) -> DateRange {
        let now = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now) else {
            fatalError("Unable to calculate date")
        }
        
        return DateRange(start: startDate, end: now)
    }
    
    // Create for custom range
    static func custom(start: Date, end: Date) -> DateRange {
        return DateRange(start: start, end: end)
    }
}
