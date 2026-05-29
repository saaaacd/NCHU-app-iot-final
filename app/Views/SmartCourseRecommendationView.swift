//
//  SmartCourseRecommendationView.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/1/23.
//

import SwiftUI

/// 智慧排課視圖：根據空堂時間推薦通識課程
struct SmartCourseRecommendationView: View {
    @ObservedObject var scheduleVM: ScheduleVM
    @StateObject private var courseStore = CourseDataStore.shared
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var selectedDay: Int = 1  // 1=週一, 2=週二, ...
    @State private var selectedPeriods: Set<Int> = []  // 選擇的節次
    @State private var filteredCourses: [Course] = []
    @State private var showingCourseDetail: Course?
    
    private let days = [
        (1, "週一"),
        (2, "週二"),
        (3, "週三"),
        (4, "週四"),
        (5, "週五")
    ]
    
    private let allPeriods = Array(1...14)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 空堂時間選擇區塊
                    freeTimeSelectionSection
                    
                    // 篩選結果
                    if !filteredCourses.isEmpty {
                        filteredCoursesSection
                    } else if !selectedPeriods.isEmpty {
                        emptyResultSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("空堂排課")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if courseStore.allCourses.isEmpty {
                    courseStore.loadCourses()
                }
            }
            .onChange(of: selectedDay) { _, _ in
                filterCourses()
            }
            .onChange(of: selectedPeriods) { _, _ in
                filterCourses()
            }
            .sheet(item: $showingCourseDetail) { course in
                CourseDetailView(course: course)
            }
        }
    }
    
    // MARK: - Free Time Selection Section
    
    private var freeTimeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇空堂時間")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // 星期選擇
            VStack(alignment: .leading, spacing: 8) {
                Text("星期")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack(spacing: 6) {
                    ForEach(days, id: \.0) { day, dayName in
                        Button(action: {
                            selectedDay = day
                        }) {
                            Text(dayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedDay == day ? .white : theme.accent.color)
                                .frame(minWidth: 45)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(selectedDay == day ? theme.accent.color : theme.accent.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // 節次選擇
            VStack(alignment: .leading, spacing: 8) {
                Text("節次（可多選）")
                    .font(.caption)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(allPeriods, id: \.self) { period in
                        Button(action: {
                            if selectedPeriods.contains(period) {
                                selectedPeriods.remove(period)
                            } else {
                                selectedPeriods.insert(period)
                            }
                        }) {
                            Text("\(period)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedPeriods.contains(period) ? .white : theme.accent.color)
                                .frame(width: 40, height: 40)
                                .background(selectedPeriods.contains(period) ? theme.accent.color : theme.accent.color.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                
                // 快速選擇按鈕
                HStack(spacing: 10) {
                    Button("全選") {
                        selectedPeriods = Set(allPeriods)
                    }
                    .font(.caption2)
                    .foregroundStyle(theme.accent.color)
                    
                    Button("清除") {
                        selectedPeriods.removeAll()
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Filtered Courses Section
    
    private var filteredCoursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("推薦通識課程")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("找到 \(filteredCourses.count) 門課程")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(filteredCourses) { course in
                RecommendedCourseCard(
                    course: course,
                    theme: theme,
                    onTap: {
                        showingCourseDetail = course
                    },
                    onAdd: {
                        addCourseToSchedule(course)
                    }
                )
            }
        }
    }
    
    // MARK: - Empty Result Section
    
    private var emptyResultSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            
            Text("沒有找到符合條件的通識課程")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("試試調整空堂時間或選擇其他節次")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Filter Logic
    
    private func filterCourses() {
        guard !selectedPeriods.isEmpty else {
            filteredCourses = []
            return
        }
        
        // 取得所有通識課程
        let allGenEdCourses = courseStore.allCourses.filter { $0.requiredType == .通識 }
        
        // 篩選：課程必須在選定的星期和節次有上課，且不與現有課程衝突
        filteredCourses = allGenEdCourses.filter { course in
            // 檢查課程是否有在選定的星期和節次上課
            let hasMatchingSchedule = course.schedules.contains { schedule in
                schedule.dayOfWeek == selectedDay &&
                !Set(schedule.periods).isDisjoint(with: selectedPeriods)
            }
            
            guard hasMatchingSchedule else { return false }
            
            // 檢查是否與現有課程衝突
            let hasConflict = scheduleVM.courses.contains { existingCourse in
                for existingSchedule in existingCourse.schedules {
                    for courseSchedule in course.schedules {
                        if existingSchedule.dayOfWeek == courseSchedule.dayOfWeek &&
                           !Set(existingSchedule.periods).isDisjoint(with: Set(courseSchedule.periods)) {
                            return true
                        }
                    }
                }
                return false
            }
            
            return !hasConflict
        }
        
        // 排序：優先顯示有課程大綱的課程
        filteredCourses.sort { course1, course2 in
            if course1.hasSyllabus != course2.hasSyllabus {
                return course1.hasSyllabus
            }
            return course1.name < course2.name
        }
    }
    
    // MARK: - Actions
    
    private func addCourseToSchedule(_ course: Course) {
        scheduleVM.addCourse(course)
        
        // 顯示成功提示
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Recommended Course Card

struct RecommendedCourseCard: View {
    let course: Course
    let theme: ThemeManager
    let onTap: () -> Void
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 課程標題和類型
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(course.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(course.dept)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 課程類型標籤
                Text(course.requiredType.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(theme.accent.color.opacity(0.2))
                    .foregroundStyle(theme.accent.color)
                    .clipShape(Capsule())
            }
            
            // 時間和地點
            HStack(spacing: 12) {
                if !course.schedules.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(course.allSchedulesDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if !course.locationDescription.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "location")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(course.locationDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            // 教師和學分
            HStack(spacing: 8) {
                if let instructor = course.instructor {
                    HStack(spacing: 3) {
                        Image(systemName: "person")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(instructor)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let credits = course.credits {
                    Text("\(credits)學分")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(.systemGreen).opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
                
                if course.hasSyllabus {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                        Text("有大綱")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(.systemBlue).opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // 操作按鈕
            HStack(spacing: 10) {
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("查看詳情")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.accent.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.accent.color.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("加入課表")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.accent.color)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SmartCourseRecommendationView(scheduleVM: ScheduleVM())
        .environmentObject(ThemeManager())
}

