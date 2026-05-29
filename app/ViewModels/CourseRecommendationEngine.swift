//
//  CourseRecommendationEngine.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 衝堂解決方案模型

struct ConflictResolution: Identifiable {
    let id = UUID()
    let conflictedCourses: [Course]
    var selectedCourseId: UUID?
    
    var hasSelection: Bool {
        selectedCourseId != nil
    }
}

// MARK: - 課程推薦引擎

@MainActor
final class CourseRecommendationEngine: ObservableObject {
    @Published var isProcessing = false
    @Published var conflictResolutions: [ConflictResolution] = []
    @Published var recommendedCourses: [Course] = []
    @Published var noTimeCourses: [Course] = []
    
    private let scheduleVM: ScheduleVM
    private let courseDataStore: CourseDataStore
    private let userProfileManager: UserProfileManager
    
    init(scheduleVM: ScheduleVM, courseDataStore: CourseDataStore, userProfileManager: UserProfileManager) {
        self.scheduleVM = scheduleVM
        self.courseDataStore = courseDataStore
        self.userProfileManager = userProfileManager
    }
    
    // MARK: - 一鍵匯入系上課程
    
    func importDepartmentCourses() async {
        print("🚀 [CourseRecommendation] 開始一鍵匯入系上課程")
        isProcessing = true
        conflictResolutions = []
        noTimeCourses = []
        
        defer { 
            isProcessing = false 
            print("🔚 [CourseRecommendation] 一鍵匯入處理完成")
        }
        
        let userProfile = userProfileManager.profile
        print("👤 [CourseRecommendation] 用戶資料 - 系所: \(userProfile.department), 年級: \(userProfile.grade)")
        
        guard userProfile.department != "請選擇系所",
              let userGrade = Int(userProfile.grade.replacingOccurrences(of: "年級", with: "")) else {
            print("❌ [CourseRecommendation] 用戶系所或年級未設定完整")
            print("   系所: \(userProfile.department)")
            print("   年級: \(userProfile.grade)")
            return
        }
        
        print("✅ [CourseRecommendation] 用戶資料驗證成功 - 系所: \(userProfile.department), 年級: \(userGrade)")
        print("📊 [CourseRecommendation] 總課程數據: \(courseDataStore.allCourses.count)")
        
        // 獲取用戶系所的必修和選修課程
        let departmentCourses = getDepartmentCourses(department: userProfile.department, grade: userGrade)
        print("📚 [CourseRecommendation] 找到 \(departmentCourses.count) 門系上課程")
        
        // 分離有時間和無時間的課程
        let (timedCourses, untimedCourses) = separateCoursesbyTime(departmentCourses)
        noTimeCourses = untimedCourses
        
        // 檢測衝堂並生成解決方案
        let conflicts = detectConflicts(in: timedCourses)
        conflictResolutions = conflicts
        
        // 自動加入沒有衝堂的課程
        let nonConflictedCourses = getNonConflictedCourses(timedCourses, conflicts: conflicts)
        for course in nonConflictedCourses {
            scheduleVM.addCourse(course)
        }
        
        print("✅ [CourseRecommendation] 自動加入 \(nonConflictedCourses.count) 門無衝堂課程")
        print("⚠️ [CourseRecommendation] 發現 \(conflicts.count) 組衝堂需要用戶選擇")
        print("📋 [CourseRecommendation] \(untimedCourses.count) 門無時間課程待處理")
    }
    
    // MARK: - 推薦通識課程
    
    func recommendGeneralEducationCourses() async {
        isProcessing = true
        recommendedCourses = []
        
        defer { isProcessing = false }
        
        let allGenEdCourses = courseDataStore.allCourses.filter { $0.requiredType == .通識 }
        let currentCourses = scheduleVM.courses
        
        // 排除已選課程
        let availableGenEd = allGenEdCourses.filter { genEdCourse in
            !currentCourses.contains { $0.name == genEdCourse.name }
        }
        
        // 基於時間空檔推薦
        let recommendedBySchedule = recommendByAvailableTimeSlots(availableGenEd)
        
        // 基於領域平衡推薦 (如果通識課程有領域資訊的話)
        let balancedRecommendations = recommendByDomainBalance(recommendedBySchedule)
        
        recommendedCourses = Array(balancedRecommendations.prefix(10)) // 最多推薦10門課
        
        print("🎯 [CourseRecommendation] 推薦了 \(recommendedCourses.count) 門通識課程")
    }
    
    // MARK: - 解決衝堂
    
    func resolveConflict(conflictId: UUID, selectedCourseId: UUID) {
        guard let conflictIndex = conflictResolutions.firstIndex(where: { $0.id == conflictId }) else { return }
        
        conflictResolutions[conflictIndex].selectedCourseId = selectedCourseId
        
        // 加入選擇的課程
        if let selectedCourse = conflictResolutions[conflictIndex].conflictedCourses.first(where: { $0.id == selectedCourseId }) {
            scheduleVM.addCourse(selectedCourse)
            print("✅ [CourseRecommendation] 用戶選擇了課程: \(selectedCourse.name)")
        }
    }
    
    func addNoTimeCourse(_ course: Course) {
        scheduleVM.addCourse(course)
        if let index = noTimeCourses.firstIndex(where: { $0.id == course.id }) {
            noTimeCourses.remove(at: index)
        }
        print("✅ [CourseRecommendation] 加入無時間課程: \(course.name)")
    }
    
    // MARK: - 私有輔助方法
    
    private func getDepartmentCourses(department: String, grade: Int) -> [Course] {
        print("🔍 [CourseRecommendation] 搜索系所課程 - 目標系所: \(department), 目標年級: \(grade)")
        
        let deptKeywords = [
            department,
            department.replacingOccurrences(of: "系", with: ""),
            department.replacingOccurrences(of: "學系", with: ""),
            department.replacingOccurrences(of: "工程學系", with: "工程"),
            department.replacingOccurrences(of: "學院", with: "")
        ]
        
        print("🎯 [CourseRecommendation] 搜索關鍵字: \(deptKeywords)")
        
        let matchedCourses = courseDataStore.allCourses.filter { course in
            // 更寬鬆的系所匹配
            let deptMatch = deptKeywords.contains { keyword in
                course.dept.contains(keyword) || keyword.contains(course.dept)
            }
            
            // 匹配年級或必修課程
            let gradeMatch = course.grade == grade || course.requiredType == .必修
            
            let typeMatch = course.requiredType == .必修 || course.requiredType == .選修
            
            if deptMatch && gradeMatch && typeMatch {
                print("✅ 匹配課程: \(course.name) - 系所:\(course.dept) 年級:\(course.grade ?? -1) 類型:\(course.requiredType)")
            }
            
            return deptMatch && gradeMatch && typeMatch
        }
        
        // 額外的調試信息
        let allDepartments = Set(courseDataStore.allCourses.map { $0.dept })
        print("📋 [CourseRecommendation] 數據庫中所有系所: \(Array(allDepartments).sorted())")
        
        let departmentCoursesCount = courseDataStore.allCourses.filter { course in
            deptKeywords.contains { keyword in
                course.dept.contains(keyword) || keyword.contains(course.dept)
            }
        }.count
        print("📊 [CourseRecommendation] 該系所總課程數: \(departmentCoursesCount)")
        
        return matchedCourses
    }
    
    /// ✅ 修正：檢查所有時段（schedules），支援多時段課程
    private func separateCoursesbyTime(_ courses: [Course]) -> (timed: [Course], untimed: [Course]) {
        var timedCourses: [Course] = []
        var untimedCourses: [Course] = []
        
        for course in courses {
            // 檢查是否有任何有效的時段
            let hasValidSchedule = course.schedules.contains { schedule in
                !schedule.periods.isEmpty && schedule.dayOfWeek > 0
            }
            
            if !hasValidSchedule || course.buildingCode == "*" || course.room == "*" {
                untimedCourses.append(course)
            } else {
                timedCourses.append(course)
            }
        }
        
        return (timedCourses, untimedCourses)
    }
    
    private func detectConflicts(in courses: [Course]) -> [ConflictResolution] {
        var conflicts: [ConflictResolution] = []
        var processedGroups: Set<Set<UUID>> = []
        
        for i in 0..<courses.count {
            for j in (i+1)..<courses.count {
                let course1 = courses[i]
                let course2 = courses[j]
                
                if hasTimeConflict(course1, course2) {
                    // 檢查是否已經處理過這組衝堂
                    let courseIds = Set([course1.id, course2.id])
                    if !processedGroups.contains(courseIds) {
                        // 找出所有相互衝堂的課程
                        let conflictGroup = findAllConflictingCourses([course1, course2], in: courses)
                        let groupIds = Set(conflictGroup.map { $0.id })
                        
                        if !processedGroups.contains(groupIds) {
                            conflicts.append(ConflictResolution(conflictedCourses: conflictGroup))
                            processedGroups.insert(groupIds)
                        }
                    }
                }
            }
        }
        
        return conflicts
    }
    
    /// ✅ 修正：檢查所有時段（schedules），支援多時段課程
    private func hasTimeConflict(_ course1: Course, _ course2: Course) -> Bool {
        // 檢查所有時段組合是否有衝突
        for schedule1 in course1.schedules {
            for schedule2 in course2.schedules {
        // 同一天且時間有重疊
                if schedule1.dayOfWeek == schedule2.dayOfWeek {
                    let periods1 = Set(schedule1.periods)
                    let periods2 = Set(schedule2.periods)
                    if !periods1.intersection(periods2).isEmpty {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func findAllConflictingCourses(_ initialConflict: [Course], in allCourses: [Course]) -> [Course] {
        var conflictGroup = Set(initialConflict)
        var changed = true
        
        while changed {
            changed = false
            for course in allCourses {
                if !conflictGroup.contains(course) {
                    for conflictCourse in conflictGroup {
                        if hasTimeConflict(course, conflictCourse) {
                            conflictGroup.insert(course)
                            changed = true
                            break
                        }
                    }
                }
            }
        }
        
        return Array(conflictGroup)
    }
    
    private func getNonConflictedCourses(_ courses: [Course], conflicts: [ConflictResolution]) -> [Course] {
        let conflictedCourseIds = Set(conflicts.flatMap { $0.conflictedCourses.map { $0.id } })
        return courses.filter { !conflictedCourseIds.contains($0.id) }
    }
    
    private func recommendByAvailableTimeSlots(_ courses: [Course]) -> [Course] {
        let currentCourses = scheduleVM.courses
        
        return courses.filter { genEdCourse in
            // 檢查是否與現有課程衝堂
            for existingCourse in currentCourses {
                if hasTimeConflict(genEdCourse, existingCourse) {
                    return false
                }
            }
            return true
        }
    }
    
    private func recommendByDomainBalance(_ courses: [Course]) -> [Course] {
        // 基於領域平衡的智能推薦
        let currentGenEdCourses = scheduleVM.courses.filter { $0.requiredType == .通識 }
        
        // 計算已選課程的領域分佈
        var domainCount: [String: Int] = [:]
        for course in currentGenEdCourses {
            if let domain = course.post110Domain {
                domainCount[domain, default: 0] += 1
            }
        }
        
        // 按領域分組可選課程
        var coursesByDomain: [String: [Course]] = [:]
        for course in courses {
            if let domain = course.post110Domain {
                coursesByDomain[domain, default: []].append(course)
            }
        }
        
        // 優先推薦較少修習的領域
        let sortedDomains = coursesByDomain.keys.sorted { domain1, domain2 in
            let count1 = domainCount[domain1, default: 0]
            let count2 = domainCount[domain2, default: 0]
            return count1 < count2 // 優先推薦修習較少的領域
        }
        
        var recommendations: [Course] = []
        let maxPerDomain = 3 // 每個領域最多推薦3門課
        
        // 從每個領域依序選取課程
        for domain in sortedDomains {
            let domainCourses = coursesByDomain[domain] ?? []
            let selectedCourses = Array(domainCourses.shuffled().prefix(maxPerDomain))
            recommendations.append(contentsOf: selectedCourses)
            
            if recommendations.count >= 10 { // 最多推薦10門課
                break
            }
        }
        
        return Array(recommendations.prefix(10))
    }
}
