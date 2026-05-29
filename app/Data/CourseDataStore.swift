//
//  CourseDataStore.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/9/23.
//

import Foundation
import Combine

@MainActor
final class CourseDataStore: ObservableObject {
    static let shared = CourseDataStore()
    
    @Published var allCourses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let csvFiles = [
        "nchu_courses_complete_2024",
        "U56_CSIE_1141",
        "U64A_EEA_1141",
        "U64F_CollegeEECS_1141",
        "gened_courses_complete"
    ]
    
    private init() {
        loadCourses()
    }
    
    func loadCourses() {
        print("📚 [CourseDataStore] Starting to load courses...")
        isLoading = true
        errorMessage = nil
        allCourses = []
        
        var loadedCoursesCount = 0
        var errors: [String] = []
        
        for fileName in csvFiles {
            do {
                print("📚 [CourseDataStore] Loading file: \(fileName).csv")
                let courses = try loadCoursesFromCSV(fileName: fileName)
                allCourses.append(contentsOf: courses)
                loadedCoursesCount += courses.count
                print("📚 [CourseDataStore] Successfully loaded \(courses.count) courses from \(fileName).csv")
            } catch {
                print("❌ [CourseDataStore] Failed to load courses from \(fileName).csv: \(error)")
                errors.append("\(fileName): \(error.localizedDescription)")
            }
        }
        
        if allCourses.isEmpty {
            if errors.isEmpty {
                errorMessage = "無法找到課程資料檔案"
            } else {
                errorMessage = "載入失敗：\(errors.joined(separator: ", "))"
            }
        } else {
            print("📚 [CourseDataStore] Successfully loaded total \(loadedCoursesCount) courses")
        }
        
        isLoading = false
    }
    
    private func loadCoursesFromCSV(fileName: String) throws -> [Course] {
        print("📚 [CourseDataStore] Looking for file: \(fileName).csv")
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            print("❌ [CourseDataStore] File not found: \(fileName).csv")
            throw CourseDataError.fileNotFound
        }
        
        print("📚 [CourseDataStore] Found file at path: \(path)")
        
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("❌ [CourseDataStore] Could not read file: \(fileName).csv")
            throw CourseDataError.fileNotFound
        }
        
        let lines = content.components(separatedBy: .newlines)
        print("📚 [CourseDataStore] File \(fileName).csv has \(lines.count) lines")
        
        guard lines.count > 1 else { 
            print("❌ [CourseDataStore] File \(fileName).csv is empty or has no data")
            throw CourseDataError.emptyFile 
        }
        
        // Skip header line
        let dataLines = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        print("📚 [CourseDataStore] Processing \(dataLines.count) data lines from \(fileName).csv")
        
        var courses: [Course] = []
        var parseErrors = 0
        
        for (index, line) in dataLines.enumerated() {
            do {
                let course = try parseCourseFromCSVLine(line)
                courses.append(course)
            } catch {
                parseErrors += 1
                if parseErrors <= 3 { // Only show first few errors to avoid spam
                    print("⚠️ [CourseDataStore] Failed to parse line \(index + 2) in \(fileName).csv: \(error)")
                    print("⚠️ [CourseDataStore] Line content: \(String(line.prefix(100)))...")
                }
            }
        }
        
        if parseErrors > 3 {
            print("⚠️ [CourseDataStore] ... and \(parseErrors - 3) more parse errors in \(fileName).csv")
        }
        
        print("📚 [CourseDataStore] Successfully parsed \(courses.count) courses from \(fileName).csv (with \(parseErrors) errors)")
        
        return courses
    }
    
    private func parseCourseFromCSVLine(_ line: String) throws -> Course {
        let components = parseCSVLine(line)
        
        // 支援兩種格式：
        // 1. 原始格式 (11欄): name,dept,requiredType,courseNumber,grade,schedule,weeks,buildingCode,room,instructor,credits  
        // 2. 通識格式 (13欄): name,dept,requiredType,courseNumber,grade,schedule,weeks,buildingCode,room,instructor,credits,post110Domain,post110Cluster
        
        guard components.count >= 11 else {
            print("⚠️ [CourseDataStore] Invalid format: expected 11+ components, got \(components.count)")
            throw CourseDataError.invalidFormat
        }
        
        let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let dept = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let requiredTypeString = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let courseNumber = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let gradeString = components[4].trimmingCharacters(in: .whitespacesAndNewlines)
        let scheduleString = components[5].trimmingCharacters(in: .whitespacesAndNewlines)
        let _ = components[6].trimmingCharacters(in: .whitespacesAndNewlines) // weeks - not used currently
        let buildingCodeString = components[7].trimmingCharacters(in: .whitespacesAndNewlines)
        let roomString = components[8].trimmingCharacters(in: .whitespacesAndNewlines)
        let instructor = components[9].trimmingCharacters(in: .whitespacesAndNewlines)
        let creditsString = components[10].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 通識課程的額外欄位 (如果存在)
        let post110Domain = components.count > 11 ? components[11].trimmingCharacters(in: .whitespacesAndNewlines) : nil
        let post110Cluster = components.count > 12 ? components[12].trimmingCharacters(in: .whitespacesAndNewlines) : nil
        
        // Parse required type
        let requiredType: Course.RequiredType
        switch requiredTypeString {
        case "必修":
            requiredType = .必修
        case "選修":
            requiredType = .選修
        case "通識":
            requiredType = .通識
        default:
            requiredType = .選修
        }
        
        // Parse grade
        let grade = Int(gradeString)
        
        // Parse credits
        let credits = Int(creditsString)
        
        // ✅ 修正：使用新的 parseSchedules 函數解析多時段課程
        // 格式：第一個數字是星期幾，後面的是節次
        // 例如："1234" = 星期1 的 2,3,4 節
        //       "234,35" = 星期2 的 3,4 節 + 星期3 的 5 節
        let schedules = parseSchedules(scheduleString)
        
        // Combine building and room
        let fullRoom = buildingCodeString + roomString
        
        // 使用新格式的初始化方法（支援多時段）
        var course = Course(
            name: name,
            dept: dept,
            requiredType: requiredType,
            schedules: schedules.isEmpty ? [CourseSchedule(dayOfWeek: 1, periods: [])] : schedules,
            grade: grade,
            buildingCode: buildingCodeString,
            room: fullRoom,
            instructor: instructor.isEmpty ? nil : instructor,
            credits: credits,
            courseNumber: courseNumber.isEmpty ? nil : courseNumber
        )
        
        // 手動設置通識額外欄位
        course.post110Domain = post110Domain?.isEmpty == true ? nil : post110Domain
        course.post110Cluster = post110Cluster?.isEmpty == true ? nil : post110Cluster
        
        return course
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var components: [String] = []
        var currentComponent = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                components.append(currentComponent)
                currentComponent = ""
            } else {
                currentComponent.append(char)
            }
        }
        
        components.append(currentComponent)
        return components
    }
    
    /// 解析時段字串
    /// ✅ 修正：正確解析 NCHU 格式 - 第一個數字是星期幾，後面的數字是節次
    /// 格式範例：
    ///   - "1234" = 星期1 的 2,3,4 節
    ///   - "234,35" = 星期2 的 3,4 節 + 星期3 的 5 節
    ///   - "4567" = 星期4 的 5,6,7 節
    private func parseTimeSlots(_ timeSlotString: String) -> (dayOfWeek: Int, periods: [Int]) {
        // Clean the input string
        let cleanedString = timeSlotString
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedString.isEmpty || cleanedString == "*" {
            return (0, []) // 無時段課程
        }
        
        // 處理多時段（用逗號分隔）- 只取第一個時段作為主要時段
        // 完整的多時段支援需要使用 parseSchedules 函數
        let firstSlot = cleanedString.components(separatedBy: ",").first ?? cleanedString
        
        // 解析單個時段：第一個數字是星期幾，後面的是節次
        let digits = firstSlot.compactMap { char -> Int? in
            if let digit = Int(String(char)), digit >= 0 && digit <= 9 {
                return digit
            }
            return nil
        }
        
        guard !digits.isEmpty else {
            return (0, [])
        }
        
        // 第一個數字是星期幾 (1-7)
        let dayOfWeek = digits[0]
        
        // 後面的數字是節次
        let periods = Array(digits.dropFirst()).map { Int($0) }
        
        return (dayOfWeek, periods)
    }
    
    /// 解析完整的多時段課程
    /// 返回 CourseSchedule 數組
    private func parseSchedules(_ timeSlotString: String) -> [CourseSchedule] {
        let cleanedString = timeSlotString
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedString.isEmpty || cleanedString == "*" {
            return []
        }
        
        var schedules: [CourseSchedule] = []
        
        // 用逗號分隔多個時段
        let slots = cleanedString.components(separatedBy: ",")
        
        for slot in slots {
            let trimmedSlot = slot.trimmingCharacters(in: .whitespaces)
            guard !trimmedSlot.isEmpty else { continue }
            
            // 解析單個時段
            let digits = trimmedSlot.compactMap { char -> Int? in
                if let digit = Int(String(char)), digit >= 0 && digit <= 9 {
                    return digit
                }
                return nil
            }
            
            guard !digits.isEmpty else { continue }
            
            // 第一個數字是星期幾 (1-7)
            let dayOfWeek = digits[0]
            guard dayOfWeek >= 1 && dayOfWeek <= 7 else { continue }
            
            // 後面的數字是節次
            let periods = Array(digits.dropFirst())
            guard !periods.isEmpty else { continue }
            
            schedules.append(CourseSchedule(dayOfWeek: dayOfWeek, periods: periods))
        }
        
        return schedules
    }
    
    private func extractBuildingCode(from room: String) -> String {
        // Extract building code from room string (e.g., "AT336" -> "AT", "S201" -> "S")
        let alphaPrefix = room.prefix { $0.isLetter }
        return String(alphaPrefix)
    }
    
    func searchCourses(
        searchText: String = "",
        department: String? = nil,
        requiredType: Course.RequiredType? = nil,
        grade: Int? = nil,
        dayOfWeek: Int? = nil
    ) -> [Course] {
        var filtered = allCourses
        
        if !searchText.isEmpty {
            filtered = filtered.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                course.dept.localizedCaseInsensitiveContains(searchText) ||
                (course.instructor?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let department = department, !department.isEmpty {
            filtered = filtered.filter { $0.dept == department }
        }
        
        if let requiredType = requiredType {
            filtered = filtered.filter { $0.requiredType == requiredType }
        }
        
        if let grade = grade {
            filtered = filtered.filter { $0.grade == grade }
        }
        
        // ✅ 修正：檢查所有時段（schedules），支援多時段課程
        if let dayOfWeek = dayOfWeek {
            filtered = filtered.filter { course in
                course.schedules.contains { $0.dayOfWeek == dayOfWeek }
            }
        }
        
        return filtered
    }
    
    var departments: [String] {
        Array(Set(allCourses.map { $0.dept })).sorted()
    }
}

enum CourseDataError: Error, LocalizedError {
    case fileNotFound
    case emptyFile
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到課程資料檔案"
        case .emptyFile:
            return "課程資料檔案為空"
        case .invalidFormat:
            return "課程資料格式錯誤"
        }
    }
}
