//
//  FreeSlotFormatter.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation

struct FreeSlotFormatter {
    
    /// Convert daily slots mapping (day -> [range]) into human-readable zh-Hant string
    /// e.g., "週一：3–4、7–9\n週二：無空檔\n週三：1–2、5–6"
    static func formatDailySlots(_ dailySlots: [Int: [ClosedRange<Int>]]) -> String {
        let weekdays = [1: "週一", 2: "週二", 3: "週三", 4: "週四", 5: "週五"]
        var result: [String] = []
        
        for day in 1...5 {
            let dayName = weekdays[day] ?? "週\(day)"
            let slots = dailySlots[day] ?? []
            
            if slots.isEmpty {
                result.append("\(dayName)：無空檔")
            } else {
                let slotsString = formatSlotRanges(slots)
                result.append("\(dayName)：\(slotsString)")
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    /// Format an array of period ranges into readable string
    /// e.g., [1...2, 5...7] -> "1–2、5–7"
    static func formatSlotRanges(_ ranges: [ClosedRange<Int>]) -> String {
        guard !ranges.isEmpty else { return "無空檔" }
        
        let formattedRanges = ranges.map { range in
            if range.lowerBound == range.upperBound {
                return "\(range.lowerBound)"
            } else {
                return "\(range.lowerBound)–\(range.upperBound)"
            }
        }
        
        return formattedRanges.joined(separator: "、")
    }
    
    /// Format a single range with period suffix
    /// e.g., 3...4 -> "3–4節"
    static func formatRangeWithSuffix(_ range: ClosedRange<Int>) -> String {
        let rangeString = formatSlotRanges([range])
        return "\(rangeString)節"
    }
    
    /// Check if there are any free slots in the week
    static func hasAnyFreeSlots(_ dailySlots: [Int: [ClosedRange<Int>]]) -> Bool {
        return dailySlots.values.contains { !$0.isEmpty }
    }
    
    /// Count total free periods in the week
    static func totalFreePeriods(_ dailySlots: [Int: [ClosedRange<Int>]]) -> Int {
        return dailySlots.values.reduce(0) { total, ranges in
            total + ranges.reduce(0) { sum, range in
                sum + range.count
            }
        }
    }
    
    /// Generate summary text for free slots
    /// e.g., "本週共有 8 個空檔時段"
    static func generateSummary(_ dailySlots: [Int: [ClosedRange<Int>]]) -> String {
        let totalPeriods = totalFreePeriods(dailySlots)
        let totalSlots = dailySlots.values.reduce(0) { total, ranges in
            total + ranges.count
        }
        
        if totalPeriods == 0 {
            return "本週沒有連續空檔時段"
        } else {
            return "本週共有 \(totalSlots) 個空檔時段，總計 \(totalPeriods) 節課"
        }
    }
    
    /// Format time period to actual time (NCHU schedule)
    static func formatPeriodToTime(_ period: Int) -> String {
        // NCHU 正確的課程時間表：
        // 第1節: 8:10-9:00, 第2節: 9:10-10:00, 第3節: 10:10-11:00, 第4節: 11:10-12:00
        // 第5節: 13:10-14:00 (下午1:10開始), 第6節: 14:10-15:00, ...
        
        let startTime: String
        let endTime: String
        
        switch period {
        case 1:
            startTime = "8:10"
            endTime = "9:00"
        case 2:
            startTime = "9:10"
            endTime = "10:00"
        case 3:
            startTime = "10:10"
            endTime = "11:00"
        case 4:
            startTime = "11:10"
            endTime = "12:00"
        case 5:
            startTime = "13:10"  // 下午1:10開始
            endTime = "14:00"
        case 6:
            startTime = "14:10"
            endTime = "15:00"
        case 7:
            startTime = "15:10"
            endTime = "16:00"
        case 8:
            startTime = "16:10"
            endTime = "17:00"
        case 9:
            startTime = "17:10"
            endTime = "18:00"
        case 10:
            startTime = "18:10"
            endTime = "19:00"
        case 11:
            startTime = "19:10"
            endTime = "20:00"
        case 12:
            startTime = "20:10"
            endTime = "21:00"
        case 13:
            startTime = "21:10"
            endTime = "22:00"
        case 14:
            startTime = "22:10"
            endTime = "23:00"
        default:
            startTime = "時間未定"
            endTime = "時間未定"
        }
        
        return "\(startTime)-\(endTime)"
    }
    
    /// Format range with actual time
    /// e.g., 3...4 -> "10:10-12:00"
    static func formatRangeWithTime(_ range: ClosedRange<Int>) -> String {
        let startPeriodTime = formatPeriodToTime(range.lowerBound)
        let endPeriodTime = formatPeriodToTime(range.upperBound)
        
        // Extract start time from first period and end time from last period
        let startTime = String(startPeriodTime.split(separator: "-")[0])
        let endTime = String(endPeriodTime.split(separator: "-")[1])
        
        return "\(startTime)-\(endTime)"
    }
}
