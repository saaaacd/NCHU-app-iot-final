//
//  Course.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation

// MARK: - Course Schedule
struct CourseSchedule: Codable, Hashable {
    let dayOfWeek: Int    // 1=Mon … 7=Sun
    let periods: [Int]    // 1..N（每節）
    
    /// Human readable day of week in Chinese
    var dayOfWeekString: String {
        switch dayOfWeek {
        case 1: return "週一"
        case 2: return "週二" 
        case 3: return "週三"
        case 4: return "週四"
        case 5: return "週五"
        case 6: return "週六"
        case 7: return "週日"
        default: return "未知"
        }
    }
    
    /// Formatted periods string (e.g., "3-4", "1", "7-9")
    var periodsString: String {
        guard !periods.isEmpty else { return "無" }
        
        let sortedPeriods = periods.sorted()
        var result: [String] = []
        var start = sortedPeriods[0]
        var end = start
        
        for i in 1..<sortedPeriods.count {
            if sortedPeriods[i] == end + 1 {
                end = sortedPeriods[i]
            } else {
                if start == end {
                    result.append("\(start)")
                } else {
                    result.append("\(start)-\(end)")
                }
                start = sortedPeriods[i]
                end = start
            }
        }
        
        // Add the last range
        if start == end {
            result.append("\(start)")
        } else {
            result.append("\(start)-\(end)")
        }
        
        return result.joined(separator: "、")
    }
    
    /// Full time description (e.g., "週一 3-4節")
    var timeDescription: String {
        return "\(dayOfWeekString) \(periodsString)節"
    }
}

struct Course: Identifiable, Codable, Hashable {
    enum RequiredType: String, Codable, CaseIterable {
        case 必修 = "必修"
        case 選修 = "選修" 
        case 通識 = "通識"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    let id: UUID
    var name: String
    var dept: String
    var requiredType: RequiredType
    var schedules: [CourseSchedule]  // 支援多個時段的新格式
    var weeks: [Int]         // 上課週數 1..18（學期週）
    var grade: Int?          // 開課年級 (1=大一, 2=大二, 3=大三, 4=大四, 0=不分年級)
    var buildingCode: String
    var room: String
    var instructor: String?
    var credits: Int?
    var courseNumber: String?  // 選課號碼 - 用於查詢課程大綱
    var post110Domain: String? // 新制通識領域 (110學年後)
    var post110Cluster: String? // 新制通識群組 (110學年後)
    
    // MARK: - 向後兼容性屬性
    
    /// 向後兼容：回傳第一個時段的星期幾（舊格式）
    var dayOfWeek: Int {
        return schedules.first?.dayOfWeek ?? 1
    }
    
    /// 向後兼容：回傳第一個時段的節次（舊格式）
    var periods: [Int] {
        return schedules.first?.periods ?? []
    }
    
    // MARK: - 新的初始化函數（支援多時段）
    init(
        name: String,
        dept: String,
        requiredType: RequiredType,
        schedules: [CourseSchedule],
        weeks: [Int] = Array(1...18),
        grade: Int? = nil,
        buildingCode: String,
        room: String,
        instructor: String? = nil,
        credits: Int? = nil,
        courseNumber: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dept = dept
        self.requiredType = requiredType
        self.schedules = schedules
        self.weeks = weeks
        self.grade = grade
        self.buildingCode = buildingCode
        self.room = room
        self.instructor = instructor
        self.credits = credits
        self.courseNumber = courseNumber
    }
    
    // Custom initializer with auto-generated UUID（向後兼容舊格式）
    init(
        name: String,
        dept: String,
        requiredType: RequiredType,
        dayOfWeek: Int,
        periods: [Int],
        weeks: [Int] = Array(1...18),
        grade: Int? = nil,
        buildingCode: String,
        room: String,
        instructor: String? = nil,
        credits: Int? = nil,
        courseNumber: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dept = dept
        self.requiredType = requiredType
        self.schedules = [CourseSchedule(dayOfWeek: dayOfWeek, periods: periods)]
        self.weeks = weeks
        self.grade = grade
        self.buildingCode = buildingCode
        self.room = room
        self.instructor = instructor
        self.credits = credits
        self.courseNumber = courseNumber
    }
    
    // Custom initializer with specified UUID（支援新格式）
    init(
        id: UUID,
        name: String,
        dept: String,
        requiredType: RequiredType,
        schedules: [CourseSchedule],
        weeks: [Int] = Array(1...18),
        grade: Int? = nil,
        buildingCode: String,
        room: String,
        instructor: String? = nil,
        credits: Int? = nil,
        courseNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dept = dept
        self.requiredType = requiredType
        self.schedules = schedules
        self.weeks = weeks
        self.grade = grade
        self.buildingCode = buildingCode
        self.room = room
        self.instructor = instructor
        self.credits = credits
        self.courseNumber = courseNumber
    }
    
    // Custom initializer with specified UUID（向後兼容舊格式）
    init(
        id: UUID,
        name: String,
        dept: String,
        requiredType: RequiredType,
        dayOfWeek: Int,
        periods: [Int],
        weeks: [Int] = Array(1...18),
        grade: Int? = nil,
        buildingCode: String,
        room: String,
        instructor: String? = nil,
        credits: Int? = nil,
        courseNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dept = dept
        self.requiredType = requiredType
        self.schedules = [CourseSchedule(dayOfWeek: dayOfWeek, periods: periods)]
        self.weeks = weeks
        self.grade = grade
        self.buildingCode = buildingCode
        self.room = room
        self.instructor = instructor
        self.credits = credits
        self.courseNumber = courseNumber
    }
    
    // MARK: - Computed Properties
    
    /// Human readable day of week in Chinese（向後兼容：只顯示第一個時段）
    var dayOfWeekString: String {
        return schedules.first?.dayOfWeekString ?? "未知"
    }
    
    /// Formatted periods string（向後兼容：只顯示第一個時段）
    var periodsString: String {
        return schedules.first?.periodsString ?? "無"
    }
    
    /// Full time description（向後兼容：只顯示第一個時段）
    var timeDescription: String {
        return schedules.first?.timeDescription ?? "未排課"
    }
    
    /// 完整的時間描述（顯示所有時段）
    var allSchedulesDescription: String {
        guard !schedules.isEmpty else { return "未排課" }
        return schedules.map { $0.timeDescription }.joined(separator: "、")
    }
    
    /// 所有涉及的星期幾
    var allDaysOfWeek: [Int] {
        return schedules.map { $0.dayOfWeek }.sorted()
    }
    
    /// 課程是否跨多天
    var isMultiDayCourse: Bool {
        return schedules.count > 1
    }
    
    /// Location description
    var locationDescription: String {
        // 如果房間號已經包含大樓代號，就不要重複顯示
        if !buildingCode.isEmpty && !room.isEmpty {
            // 檢查房間號是否已經以大樓代號開頭
            if room.hasPrefix(buildingCode) {
                return room
            } else {
                return "\(buildingCode) \(room)"
            }
        } else if !room.isEmpty {
            return room
        } else if !buildingCode.isEmpty {
            return buildingCode
        } else {
            return ""
        }
    }
    
    /// Grade description
    var gradeString: String {
        guard let grade = grade else { return "不分年級" }
        switch grade {
        case 1: return "大一"
        case 2: return "大二"
        case 3: return "大三"
        case 4: return "大四"
        case 0: return "不分年級"
        default: return "其他"
        }
    }
    
    /// Generate NCHU syllabus URL from course number
    var syllabusURL: URL? {
        guard let courseNumber = courseNumber, !courseNumber.isEmpty else { return nil }
        
        // 中興大學課程大綱查詢 URL 格式
        // 基於實際的系統可能需要調整 URL 結構
        let urlString = "https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_syllabus?v_crseno=\(courseNumber)"
        return URL(string: urlString)
    }
    
    /// Check if course has syllabus available
    var hasSyllabus: Bool {
        return courseNumber != nil && !courseNumber!.isEmpty
    }
}

// MARK: - Sample Data for Previews

extension Course {
    static let sampleCourses: [Course] = [
        Course(
            name: "離散數學",
            dept: "資訊工程學系",
            requiredType: .必修,
            dayOfWeek: 2,
            periods: [3, 4],
            grade: 1,
            buildingCode: "工綜館",
            room: "204",
            instructor: "張教授",
            credits: 3,
            courseNumber: "5606001"
        ),
        Course(
            name: "資料結構",
            dept: "資訊工程學系", 
            requiredType: .必修,
            dayOfWeek: 4,
            periods: [7, 8, 9],
            grade: 2,
            buildingCode: "工綜館",
            room: "301",
            instructor: "李教授",
            credits: 3,
            courseNumber: "5606002"
        ),
        Course(
            name: "大學精進英文(二)中級",
            dept: "語言中心",
            requiredType: .通識,
            dayOfWeek: 4,
            periods: [3, 4],
            grade: 0,
            buildingCode: "語言中心",
            room: "A601",
            instructor: "王老師",
            credits: 2,
            courseNumber: "1001025"
        ),
        Course(
            name: "計算機概論",
            dept: "資訊工程學系",
            requiredType: .必修,
            dayOfWeek: 1,
            periods: [1, 2],
            grade: 1,
            buildingCode: "工綜館",
            room: "101",
            instructor: "陳教授",
            credits: 3,
            courseNumber: "5606003"
        ),
        // 跨天課程示例：微積分（週二3-4節 + 週三5節）
        Course(
            name: "微積分(一)",
            dept: "應用數學系",
            requiredType: .必修,
            schedules: [
                CourseSchedule(dayOfWeek: 2, periods: [3, 4]),
                CourseSchedule(dayOfWeek: 3, periods: [5])
            ],
            grade: 1,
            buildingCode: "AT",
            room: "336",
            instructor: "戴教授",
            credits: 3,
            courseNumber: "1226"
        )
    ]
}
