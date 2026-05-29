//
//  ScheduleVM.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation
import Combine

@MainActor
final class ScheduleVM: ObservableObject {
    @Published var courses: [Course] = [] {
        didSet {
            saveCourses()
        }
    }
    @Published var minFreeSlotLength: Int = 2
    @Published var isImporting: Bool = false
    @Published var importWarnings: [String] = []
    
    init() {
        Task {
            await loadCourses()
        }
    }
    
    // MARK: - Conflict Detection
    
    /// Return pairs of conflicting courses (same day & overlapping periods)
    /// ✅ 修正：檢查所有時段（schedules），支援多時段課程
    func conflicts(in courses: [Course]) -> [(Course, Course)] {
        var conflictPairs: [(Course, Course)] = []
        
        for i in 0..<courses.count {
            for j in (i + 1)..<courses.count {
                let course1 = courses[i]
                let course2 = courses[j]
                
                // ✅ 檢查所有時段組合是否有衝突
                var hasConflict = false
                outerLoop: for schedule1 in course1.schedules {
                    for schedule2 in course2.schedules {
                // Check if they're on the same day
                        if schedule1.dayOfWeek == schedule2.dayOfWeek {
                // Check if their periods overlap
                            let periods1 = Set(schedule1.periods)
                            let periods2 = Set(schedule2.periods)
                
                if !periods1.isDisjoint(with: periods2) {
                                hasConflict = true
                                break outerLoop
                            }
                        }
                    }
                }
                
                if hasConflict {
                    conflictPairs.append((course1, course2))
                }
            }
        }
        
        return conflictPairs
    }
    
    /// Convenience method: set of course IDs that appear in any conflict pair
    func conflictedCourseIDs(in courses: [Course]) -> Set<UUID> {
        let conflictPairs = conflicts(in: courses)
        var conflictedIDs: Set<UUID> = []
        
        for (course1, course2) in conflictPairs {
            conflictedIDs.insert(course1.id)
            conflictedIDs.insert(course2.id)
        }
        
        return conflictedIDs
    }
    
    // MARK: - Free Slot Calculation
    
    /// Compute contiguous free slots for a given day; drop intervals shorter than minLength
    /// ✅ 修正：檢查所有時段（schedules），支援多時段課程
    func freeSlots(
        courses: [Course],
        on day: Int,
        totalPeriods: ClosedRange<Int> = 1...14,
        minLength: Int = 2
    ) -> [ClosedRange<Int>] {
        // Get all occupied periods for this day
        // ✅ 檢查所有時段，而不只是第一個
        let occupiedPeriods = Set(
            courses
                .flatMap { course in
                    course.schedules
                .filter { $0.dayOfWeek == day }
                .flatMap { $0.periods }
                }
        )
        
        // Find all free periods
        let freePeriods = totalPeriods.filter { !occupiedPeriods.contains($0) }
        
        // Group consecutive periods into ranges
        guard !freePeriods.isEmpty else { return [] }
        
        var ranges: [ClosedRange<Int>] = []
        var start = freePeriods[0]
        var end = start
        
        for i in 1..<freePeriods.count {
            if freePeriods[i] == end + 1 {
                end = freePeriods[i]
            } else {
                // End of current range
                let range = start...end
                if range.count >= minLength {
                    ranges.append(range)
                }
                start = freePeriods[i]
                end = start
            }
        }
        
        // Don't forget the last range
        let lastRange = start...end
        if lastRange.count >= minLength {
            ranges.append(lastRange)
        }
        
        return ranges
    }
    
    /// Calculate free slots for all weekdays (Monday to Friday)
    func calculateWeeklyFreeSlots() -> [Int: [ClosedRange<Int>]] {
        var weeklySlots: [Int: [ClosedRange<Int>]] = [:]
        
        for day in 1...5 { // Monday to Friday
            weeklySlots[day] = freeSlots(
                courses: courses,
                on: day,
                minLength: minFreeSlotLength
            )
        }
        
        return weeklySlots
    }
    
    // MARK: - Today's Schedule
    
    /// Get current weekday (1=Mon, 2=Tue, ..., 7=Sun)
    private var currentWeekday: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convert Calendar weekday (1=Sun, 2=Mon, ...) to our format (1=Mon, 2=Tue, ...)
        return weekday == 1 ? 7 : weekday - 1
    }
    
    /// Get today's courses sorted by period
    /// ✅ 修正：檢查所有時段（schedules），支援多時段課程
    func getTodayCourses() -> [Course] {
        let today = currentWeekday
        return courses
            .filter { course in
                // 檢查任一時段是否在今天
                course.schedules.contains { $0.dayOfWeek == today }
            }
            .sorted { course1, course2 in
                // 取得今天的時段中最早的節次來排序
                let minPeriod1 = course1.schedules
                    .filter { $0.dayOfWeek == today }
                    .flatMap { $0.periods }
                    .min() ?? Int.max
                let minPeriod2 = course2.schedules
                    .filter { $0.dayOfWeek == today }
                    .flatMap { $0.periods }
                    .min() ?? Int.max
                return minPeriod1 < minPeriod2
            }
    }
    
    /// Get courses for a specific weekday
    /// ✅ 修正：檢查所有時段（schedules），支援多時段課程
    func getCoursesForDay(_ dayOfWeek: Int) -> [Course] {
        return courses
            .filter { course in
                // 檢查任一時段是否在指定的星期
                course.schedules.contains { $0.dayOfWeek == dayOfWeek }
            }
            .sorted { course1, course2 in
                // 取得該天的時段中最早的節次來排序
                let minPeriod1 = course1.schedules
                    .filter { $0.dayOfWeek == dayOfWeek }
                    .flatMap { $0.periods }
                    .min() ?? Int.max
                let minPeriod2 = course2.schedules
                    .filter { $0.dayOfWeek == dayOfWeek }
                    .flatMap { $0.periods }
                    .min() ?? Int.max
                return minPeriod1 < minPeriod2
            }
    }
    
    /// Check if today is a weekday (Mon-Fri)
    var isTodayWeekday: Bool {
        let today = currentWeekday
        return today >= 1 && today <= 5
    }
    
    /// Get next course today (if any)
    func getNextCourseToday() -> Course? {
        let todayCourses = getTodayCourses()
        guard !todayCourses.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        // Find next course based on time
        for course in todayCourses {
            guard let firstPeriod = course.periods.min() else { continue }
            let courseStartTime = periodToMinutes(firstPeriod)
            
            if currentTimeInMinutes < courseStartTime {
                return course
            }
        }
        
        return nil
    }
    
    /// Convert period number to minutes since midnight
    private func periodToMinutes(_ period: Int) -> Int {
        // NCHU 正確的課程時間表：
        // 第1節: 8:10, 第2節: 9:10, 第3節: 10:10, 第4節: 11:10
        // 第5節: 13:10 (下午1:10開始), 第6節: 14:10, ...
        
        switch period {
        case 1: return 8 * 60 + 10   // 8:10
        case 2: return 9 * 60 + 10   // 9:10
        case 3: return 10 * 60 + 10  // 10:10
        case 4: return 11 * 60 + 10  // 11:10
        case 5: return 13 * 60 + 10  // 13:10 (下午1:10)
        case 6: return 14 * 60 + 10  // 14:10
        case 7: return 15 * 60 + 10  // 15:10
        case 8: return 16 * 60 + 10  // 16:10
        case 9: return 17 * 60 + 10  // 17:10
        case 10: return 18 * 60 + 10 // 18:10
        case 11: return 19 * 60 + 10 // 19:10
        case 12: return 20 * 60 + 10 // 20:10
        case 13: return 21 * 60 + 10 // 21:10
        case 14: return 22 * 60 + 10 // 22:10
        default: return 0
        }
    }
    
    // MARK: - Course Management
    
    /// Add a single course
    func addCourse(_ course: Course) {
        courses.append(course)
    }
    
    /// Add multiple courses
    func addCourses(_ newCourses: [Course]) {
        courses.append(contentsOf: newCourses)
    }
    
    /// Update existing course
    func updateCourse(_ oldCourse: Course, with newCourse: Course) {
        if let index = courses.firstIndex(where: { $0.id == oldCourse.id }) {
            courses[index] = newCourse
        }
    }
    
    /// Remove course by ID
    func removeCourse(withID id: UUID) {
        courses.removeAll { $0.id == id }
    }
    
    /// Clear all courses
    func clearAllCourses() {
        courses.removeAll()
        importWarnings.removeAll()
    }
    
    /// Filter courses by search keyword
    func filteredCourses(searchText: String) -> [Course] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return courses
        }
        
        let keyword = searchText.lowercased()
        return courses.filter { course in
            course.name.lowercased().contains(keyword) ||
            course.instructor?.lowercased().contains(keyword) == true ||
            course.dept.lowercased().contains(keyword)
        }
    }
    
    // MARK: - Import Status Management
    
    /// Set importing status and clear previous warnings
    func setImporting(_ importing: Bool) {
        isImporting = importing
        if importing {
            importWarnings.removeAll()
        }
    }
    
    /// Add import warnings
    func addImportWarnings(_ warnings: [String]) {
        importWarnings.append(contentsOf: warnings)
    }
    
    // MARK: - Data Persistence
    
    private func saveCourses() {
        let coursesToSave = self.courses // Capture courses on main actor
        Task {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    do {
                        let data = try JSONEncoder().encode(coursesToSave)
                        UserDefaults.standard.set(data, forKey: "SavedCourses")
                        print("✅ 課程資料已儲存")
                    } catch {
                        print("❌ 課程資料儲存失敗: \(error)")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func loadCourses() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let data = UserDefaults.standard.data(forKey: "SavedCourses") else {
                    print("📝 沒有儲存的課程資料")
                    continuation.resume()
                    return
                }
                
                do {
                    let loadedCourses = try JSONDecoder().decode([Course].self, from: data)
                    DispatchQueue.main.async {
                        self.courses = loadedCourses
                        print("✅ 已載入 \(loadedCourses.count) 門課程")
                        continuation.resume()
                    }
                } catch {
                    print("❌ 課程資料載入失敗: \(error)")
                    // 如果解碼失敗，保持空陣列
                    DispatchQueue.main.async {
                        self.courses = []
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// 手動儲存課程資料（可選用）
    func saveCoursesManually() {
        saveCourses()
    }
    
    /// 清空儲存的課程資料
    func clearSavedCourses() {
        UserDefaults.standard.removeObject(forKey: "SavedCourses")
        courses.removeAll()
        print("🗑️ 已清空所有課程資料")
    }
}
