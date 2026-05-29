//
//  ScheduleExporter.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/1/23.
//

import Foundation
import UIKit
import SwiftUI

/// 課表匯出工具
struct ScheduleExporter {
    
    // MARK: - CSV Export
    
    /// 將課程匯出為 CSV 格式
    static func exportToCSV(courses: [Course]) -> Data? {
        var csvLines: [String] = []
        
        // CSV 標題行
        let headers = [
            "課程名稱", "系所", "類型", "選課號碼", "年級",
            "時段", "週數", "大樓", "教室", "授課教師", "學分"
        ]
        csvLines.append(headers.joined(separator: ","))
        
        // 課程資料行
        for course in courses.sorted(by: { $0.name < $1.name }) {
            let scheduleString = course.schedules.map { schedule in
                "\(schedule.dayOfWeekString) \(schedule.periodsString)節"
            }.joined(separator: "、")
            
            let weeksString = course.weeks.sorted().map { String($0) }.joined(separator: "|")
            
            let row = [
                escapeCSV(course.name),
                escapeCSV(course.dept),
                course.requiredType.displayName,
                course.courseNumber ?? "",
                course.grade.map { String($0) } ?? "",
                escapeCSV(scheduleString),
                weeksString,
                escapeCSV(course.buildingCode),
                escapeCSV(course.room),
                escapeCSV(course.instructor ?? ""),
                course.credits.map { String($0) } ?? ""
            ]
            csvLines.append(row.joined(separator: ","))
        }
        
        let csvString = csvLines.joined(separator: "\n")
        return csvString.data(using: .utf8)
    }
    
    /// 將課程匯出為 iCal 格式（可匯入行事曆）
    static func exportToiCal(courses: [Course], semester: String = "114-1") -> Data? {
        var icalLines: [String] = []
        
        icalLines.append("BEGIN:VCALENDAR")
        icalLines.append("VERSION:2.0")
        icalLines.append("PRODID:-//NCHUHelper//課表匯出//ZH")
        icalLines.append("CALSCALE:GREGORIAN")
        icalLines.append("METHOD:PUBLISH")
        icalLines.append("X-WR-CALNAME:中興大學課表 \(semester)")
        icalLines.append("X-WR-TIMEZONE:Asia/Taipei")
        
        // 計算學期開始日期（從學期字串解析，例如 "114-1" = 2025年2月）
        // 114學年度第一學期通常從2月開始
        let calendar = Calendar.current
        let components = semester.components(separatedBy: "-")
        var year = 2025  // 預設值
        var month = 2    // 預設值（第一學期通常2月開始）
        
        if components.count >= 1, let academicYear = Int(components[0]) {
            // 114學年度 = 2025年（114 + 1911 = 2025）
            year = academicYear + 1911
        }
        if components.count >= 2, let semesterNum = Int(components[1]) {
            // 第一學期：2月，第二學期：9月
            month = semesterNum == 1 ? 2 : 9
        }
        
        // 找到該月的第一個週一作為學期開始
        var semesterStart = DateComponents()
        semesterStart.year = year
        semesterStart.month = month
        semesterStart.day = 1
        guard let firstDayOfMonth = calendar.date(from: semesterStart) else {
            return nil
        }
        
        // 找到第一個週一
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Calendar.weekday: 1=Sun, 2=Mon, ..., 7=Sat
        // 我們需要週一（2），所以計算偏移
        let daysToMonday = weekday == 1 ? 1 : (9 - weekday) % 7
        guard let startDate = calendar.date(byAdding: .day, value: daysToMonday, to: firstDayOfMonth) else {
            return nil
        }
        
        // 為每個課程的每個時段建立事件
        for course in courses {
            for schedule in course.schedules {
                let dayOfWeek = schedule.dayOfWeek  // 1=Mon, 2=Tue, ..., 5=Fri
                let periods = schedule.periods.sorted()
                
                guard let firstPeriod = periods.first else { continue }
                
                // 計算該週幾的日期（從學期開始的週一算起）
                // dayOfWeek: 1=Mon, 2=Tue, ..., 5=Fri
                // 偏移量：週一=0, 週二=1, ..., 週五=4
                let weekdayOffset = dayOfWeek - 1
                guard let firstClassDate = calendar.date(byAdding: .day, value: weekdayOffset, to: startDate) else {
                    continue
                }
                
                // 計算上課時間
                let startTime = periodToTime(firstPeriod, isStart: true)
                let endTime = periodToTime(periods.last ?? firstPeriod, isStart: false)
                
                // 為每週建立事件（只包含指定的週數）
                for week in course.weeks.sorted() {
                    guard let classDate = calendar.date(byAdding: .weekOfYear, value: week - 1, to: firstClassDate) else {
                        continue
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
                    dateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
                    
                    let startDateTime = calendar.date(bySettingHour: startTime.hour, minute: startTime.minute, second: 0, of: classDate) ?? classDate
                    let endDateTime = calendar.date(bySettingHour: endTime.hour, minute: endTime.minute, second: 0, of: classDate) ?? classDate
                    
                    let dtstart = dateFormatter.string(from: startDateTime)
                    let dtend = dateFormatter.string(from: endDateTime)
                    
                    icalLines.append("BEGIN:VEVENT")
                    icalLines.append("UID:\(course.id.uuidString)-\(week)@nchuhelper")
                    icalLines.append("DTSTART:\(dtstart)")
                    icalLines.append("DTEND:\(dtend)")
                    icalLines.append("SUMMARY:\(course.name)")
                    icalLines.append("DESCRIPTION:\(course.dept) - \(course.requiredType.displayName)\\n授課教師: \(course.instructor ?? "未指定")\\n教室: \(course.locationDescription)")
                    icalLines.append("LOCATION:\(course.locationDescription)")
                    icalLines.append("END:VEVENT")
                }
            }
        }
        
        icalLines.append("END:VCALENDAR")
        
        let icalString = icalLines.joined(separator: "\r\n")
        return icalString.data(using: .utf8)
    }
    
    // MARK: - Helper Methods
    
    /// 轉義 CSV 欄位（處理包含逗號、引號的情況）
    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    /// 將節次轉換為時間
    private static func periodToTime(_ period: Int, isStart: Bool) -> (hour: Int, minute: Int) {
        switch period {
        case 1: return isStart ? (8, 10) : (9, 0)
        case 2: return isStart ? (9, 10) : (10, 0)
        case 3: return isStart ? (10, 10) : (11, 0)
        case 4: return isStart ? (11, 10) : (12, 0)
        case 5: return isStart ? (13, 10) : (14, 0)
        case 6: return isStart ? (14, 10) : (15, 0)
        case 7: return isStart ? (15, 10) : (16, 0)
        case 8: return isStart ? (16, 10) : (17, 0)
        case 9: return isStart ? (17, 10) : (18, 0)
        case 10: return isStart ? (18, 10) : (19, 0)
        case 11: return isStart ? (19, 10) : (20, 0)
        case 12: return isStart ? (20, 10) : (21, 0)
        case 13: return isStart ? (21, 10) : (22, 0)
        case 14: return isStart ? (22, 10) : (23, 0)
        default: return (8, 10)
        }
    }
    
    // MARK: - Image Export
    
    /// 將課表匯出為圖片（適合當桌布）
    static func exportToImage(
        courses: [Course],
        theme: ThemeManager,
        style: WallpaperStyle = .modern,
        size: WallpaperSize = .iphone
    ) -> UIImage? {
        let imageSize = size.dimensions
        return ScheduleImageRenderer.renderScheduleImage(
            courses: courses,
            theme: theme,
            size: imageSize,
            style: style
        )
    }
}

/// 桌布尺寸選項
enum WallpaperSize: String, CaseIterable {
    case iphone = "iPhone"
    case iphonePlus = "iPhone Plus"
    case ipad = "iPad"
    
    var dimensions: CGSize {
        switch self {
        case .iphone:
            // iPhone 標準尺寸（例如 iPhone 14 Pro）
            return CGSize(width: 1179, height: 2556)
        case .iphonePlus:
            // iPhone Plus/Max 尺寸
            return CGSize(width: 1290, height: 2796)
        case .ipad:
            // iPad 尺寸
            return CGSize(width: 2048, height: 2732)
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

