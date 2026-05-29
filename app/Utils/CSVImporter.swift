//
//  CSVImporter.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation

struct CSVImportResult {
    let courses: [Course]
    let warnings: [String]
}

enum CSVImportError: Error, LocalizedError {
    case badHeader
    case badRow(Int, String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .badHeader:
            return "CSV 標題行格式錯誤"
        case .badRow(let row, let reason):
            return "第 \(row) 行資料錯誤: \(reason)"
        case .invalidData:
            return "CSV 資料格式無效"
        }
    }
}

struct CSVImporter {
    
    /// Expected CSV header columns (fixed order):
    /// name,dept,requiredType,schedule,weeks,buildingCode,room,instructor,credits
    static let expectedHeaders = [
        "name", "dept", "requiredType", "schedule", 
        "weeks", "buildingCode", "room", "instructor", "credits"
    ]
    
    /// Legacy CSV header columns for backward compatibility:
    /// name,dept,requiredType,dayOfWeek,periods,grade,buildingCode,room,instructor,credits,courseNumber
    static let legacyHeaders = [
        "name", "dept", "requiredType", "dayOfWeek", 
        "periods", "grade", "buildingCode", "room", "instructor", "credits", "courseNumber"
    ]
    
    /// Parse CSV data into courses
    /// 
    /// 新格式 (preferred): name,dept,requiredType,schedule,weeks,buildingCode,room,instructor,credits
    /// - schedule: 時段格式如 "234,35" (週二3,4節+週三5節) 或 "1567" (週一5,6,7節)
    /// - weeks: 週數 "1|2|3|...|18" 或空白表示全學期
    /// 
    /// 舊格式 (legacy): name,dept,requiredType,dayOfWeek,periods,grade,buildingCode,room,instructor,credits,courseNumber
    /// - periods: 節次 "3|4|5", requiredType: {必修,選修,通識}, grade: 1=大一,2=大二,3=大三,4=大四,0=不分年級
    static func parseCourses(from data: Data) throws -> CSVImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw CSVImportError.invalidData
        }
        
        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVImportError.invalidData
        }
        
        // Validate header and detect format
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine)
        let normalizedHeaders = headers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Detect format (new vs legacy)
        let isNewFormat: Bool
        if normalizedHeaders.contains("schedule") && normalizedHeaders.contains("weeks") {
            // New format
            let expectedNormalized = expectedHeaders.map { $0.lowercased() }
            guard normalizedHeaders.count >= expectedNormalized.count else {
                throw CSVImportError.badHeader
            }
            isNewFormat = true
        } else if normalizedHeaders.contains("dayofweek") && normalizedHeaders.contains("periods") {
            // Legacy format
            let legacyNormalized = legacyHeaders.map { $0.lowercased() }
            guard normalizedHeaders.count >= legacyNormalized.count else {
                throw CSVImportError.badHeader
            }
            isNewFormat = false
        } else {
            throw CSVImportError.badHeader
        }
        
        // Parse data rows
        var courses: [Course] = []
        var warnings: [String] = []
        
        for (index, line) in lines.dropFirst().enumerated() {
            let rowNumber = index + 2 // +2 because we dropped first line and 0-based index
            
            do {
                if isNewFormat {
                    if let course = try parseNewFormatCourseLine(line, rowNumber: rowNumber) {
                        courses.append(course)
                    }
                } else {
                    if let course = try parseLegacyCourseLine(line, rowNumber: rowNumber) {
                        courses.append(course)
                    }
                }
            } catch {
                warnings.append(error.localizedDescription)
            }
        }
        
        return CSVImportResult(courses: courses, warnings: warnings)
    }
    
    /// Parse a single CSV line into array of fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Don't forget the last field
        fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return fields
    }
    
    /// Parse a single course line (legacy format)
    private static func parseLegacyCourseLine(_ line: String, rowNumber: Int) throws -> Course? {
        let fields = parseCSVLine(line)
        
        guard fields.count >= legacyHeaders.count else {
            throw CSVImportError.badRow(rowNumber, "欄位數量不足 (需要 \(legacyHeaders.count) 個，得到 \(fields.count) 個)")
        }
        
        // Extract fields by position
        let name = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let dept = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let requiredTypeString = fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let dayOfWeekString = fields[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let periodsString = fields[4].trimmingCharacters(in: .whitespacesAndNewlines)
        let gradeFieldString = fields[5].trimmingCharacters(in: .whitespacesAndNewlines)
        let buildingCode = fields[6].trimmingCharacters(in: .whitespacesAndNewlines)
        let room = fields[7].trimmingCharacters(in: .whitespacesAndNewlines)
        let instructor = fields[8].trimmingCharacters(in: .whitespacesAndNewlines)
        let creditsString = fields[9].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip empty rows
        guard !name.isEmpty else { return nil }
        
        // Parse required type
        guard let requiredType = Course.RequiredType(rawValue: requiredTypeString) else {
            throw CSVImportError.badRow(rowNumber, "無效的課程類型: \(requiredTypeString) (應為: 必修, 選修, 通識)")
        }
        
        // Parse day of week
        guard let dayOfWeek = Int(dayOfWeekString), (1...7).contains(dayOfWeek) else {
            throw CSVImportError.badRow(rowNumber, "無效的星期: \(dayOfWeekString) (應為 1-7)")
        }
        
        // Parse periods (separated by |)
        let periods: [Int]
        if periodsString.isEmpty {
            periods = []
        } else {
            let periodStrings = periodsString.components(separatedBy: "|")
            periods = try periodStrings.compactMap { periodStr in
                let trimmed = periodStr.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }
                guard let period = Int(trimmed), period > 0 else {
                    throw CSVImportError.badRow(rowNumber, "無效的節次: \(trimmed)")
                }
                return period
            }
        }
        
        // Parse grade (0=不分年級, 1=大一, 2=大二, 3=大三, 4=大四)
        let grade: Int?
        if gradeFieldString.isEmpty {
            grade = nil // Default to no specific grade
        } else {
            guard let gradeValue = Int(gradeFieldString), (0...4).contains(gradeValue) else {
                throw CSVImportError.badRow(rowNumber, "無效的年級: \(gradeFieldString) (應為 0=不分年級, 1=大一, 2=大二, 3=大三, 4=大四)")
            }
            grade = gradeValue
        }
        
        // Parse credits (optional)
        let credits: Int?
        if creditsString.isEmpty {
            credits = nil
        } else {
            guard let creditValue = Int(creditsString), creditValue >= 0 else {
                throw CSVImportError.badRow(rowNumber, "無效的學分數: \(creditsString)")
            }
            credits = creditValue
        }
        
        // Parse course number (optional)
        let courseNumber: String?
        if fields.count > 10 && !fields[10].isEmpty {
            courseNumber = fields[10].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            courseNumber = nil
        }
        
        // Create course
        return Course(
            name: name,
            dept: dept,
            requiredType: requiredType,
            dayOfWeek: dayOfWeek,
            periods: periods,
            weeks: Array(1...18), // Legacy format defaults to full semester
            grade: grade,
            buildingCode: buildingCode,
            room: room,
            instructor: instructor.isEmpty ? nil : instructor,
            credits: credits,
            courseNumber: courseNumber
        )
    }
    
    /// Parse a single course line (new format)
    /// Format: name,dept,requiredType,schedule,weeks,buildingCode,room,instructor,credits
    private static func parseNewFormatCourseLine(_ line: String, rowNumber: Int) throws -> Course? {
        let fields = parseCSVLine(line)
        
        guard fields.count >= expectedHeaders.count else {
            throw CSVImportError.badRow(rowNumber, "欄位數量不足 (需要 \(expectedHeaders.count) 個，得到 \(fields.count) 個)")
        }
        
        // Extract fields by position
        let name = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let dept = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let requiredTypeString = fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let scheduleString = fields[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let weeksString = fields[4].trimmingCharacters(in: .whitespacesAndNewlines)
        let buildingCode = fields[5].trimmingCharacters(in: .whitespacesAndNewlines)
        let room = fields[6].trimmingCharacters(in: .whitespacesAndNewlines)
        let instructor = fields[7].trimmingCharacters(in: .whitespacesAndNewlines)
        let creditsString = fields[8].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip empty rows
        guard !name.isEmpty else { return nil }
        
        // Parse required type
        guard let requiredType = Course.RequiredType(rawValue: requiredTypeString) else {
            throw CSVImportError.badRow(rowNumber, "無效的課程類型: \(requiredTypeString) (應為: 必修, 選修, 通識)")
        }
        
        // Parse schedule string (e.g., "234,35" or "1567")
        let schedules: [CourseSchedule]
        do {
            schedules = try parseScheduleString(scheduleString, rowNumber: rowNumber)
        } catch {
            throw CSVImportError.badRow(rowNumber, "無效的時段格式: \(scheduleString)")
        }
        
        // Parse weeks (separated by |) or default to full semester
        let weeks: [Int]
        if weeksString.isEmpty {
            weeks = Array(1...18) // Default to full semester
        } else {
            let weekStrings = weeksString.components(separatedBy: "|")
            weeks = try weekStrings.compactMap { weekStr in
                let trimmed = weekStr.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }
                guard let week = Int(trimmed), (1...18).contains(week) else {
                    throw CSVImportError.badRow(rowNumber, "無效的週數: \(trimmed)")
                }
                return week
            }
        }
        
        // Parse credits (optional)
        let credits: Int?
        if creditsString.isEmpty {
            credits = nil
        } else {
            guard let creditValue = Int(creditsString), creditValue >= 0 else {
                throw CSVImportError.badRow(rowNumber, "無效的學分數: \(creditsString)")
            }
            credits = creditValue
        }
        
        // Create course with new format
        return Course(
            name: name,
            dept: dept,
            requiredType: requiredType,
            schedules: schedules,
            weeks: weeks,
            buildingCode: buildingCode,
            room: room,
            instructor: instructor.isEmpty ? nil : instructor,
            credits: credits
        )
    }
    
    /// Parse schedule string into CourseSchedule array
    /// Examples: "234,35" -> [CourseSchedule(day:2, periods:[3,4]), CourseSchedule(day:3, periods:[5])]
    ///          "1567" -> [CourseSchedule(day:1, periods:[5,6,7])]
    private static func parseScheduleString(_ scheduleString: String, rowNumber: Int) throws -> [CourseSchedule] {
        guard !scheduleString.isEmpty else {
            throw CSVImportError.badRow(rowNumber, "時段字串不能為空")
        }
        
        // Handle multiple time segments separated by commas
        let segments = scheduleString.components(separatedBy: ",")
        var schedules: [CourseSchedule] = []
        
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // First digit is day of week, rest are periods
            guard trimmed.count >= 2 else {
                throw CSVImportError.badRow(rowNumber, "時段格式錯誤: \(trimmed)")
            }
            
            let dayOfWeek = Int(String(trimmed.first!))
            guard let day = dayOfWeek, (1...7).contains(day) else {
                throw CSVImportError.badRow(rowNumber, "無效的星期: \(trimmed.first!) (應為 1-7)")
            }
            
            // Extract periods
            let periodChars = String(trimmed.dropFirst())
            var periods: [Int] = []
            
            for char in periodChars {
                guard let period = Int(String(char)), period > 0 else {
                    throw CSVImportError.badRow(rowNumber, "無效的節次: \(char)")
                }
                periods.append(period)
            }
            
            schedules.append(CourseSchedule(dayOfWeek: day, periods: periods))
        }
        
        guard !schedules.isEmpty else {
            throw CSVImportError.badRow(rowNumber, "無法解析時段: \(scheduleString)")
        }
        
        return schedules
    }
}
