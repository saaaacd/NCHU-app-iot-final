//
//  CoursePickerView.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/9/23.
//

import SwiftUI

struct CoursePickerView: View {
    let timeSlot: TimeSlot?
    let existingCourses: [Course]
    let onCourseSelected: (Course) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject private var courseDataStore = CourseDataStore.shared
    
    @State private var searchText = ""
    @State private var selectedDepartment: String? = nil
    @State private var selectedRequiredType: Course.RequiredType? = nil
    @State private var selectedGrade: Int? = nil
    @State private var selectedDayOfWeek: Int? = nil
    @State private var displayCourses: [Course] = []
    @State private var hasInitialized = false  // ✅ 追蹤是否已初始化
    
    // 可用的系所列表
    private var availableDepartments: [String] {
        let allDepts = Set(courseDataStore.allCourses.map { $0.dept })
        // 過濾掉不應該出現在系所列表中的值
        let filteredDepts = allDepts.filter { dept in
            !dept.isEmpty && 
            dept != "必修" && 
            dept != "選修" && 
            dept != "通識" &&
            (dept.contains("系") || dept.contains("學院") || dept.contains("中心") || dept.contains("所"))
        }
        return Array(filteredDepts).sorted()
    }
    
    // 🎯 強制過濾課程的函數
    private func updateDisplayCourses() {
        let allCourses = courseDataStore.allCourses
        print("🔍 [updateDisplayCourses] Total courses available: \(allCourses.count)")
        print("🔍 [updateDisplayCourses] timeSlot: \(String(describing: timeSlot))")
        
        // Step 1: 如果有timeSlot，首先只保留匹配該時間段的課程
        var courses: [Course]
        if let timeSlot = timeSlot {
            print("🎯 [updateDisplayCourses] FORCE Filtering for timeSlot: \(timeSlot.displayDay) 第\(timeSlot.period)節")
            
            courses = allCourses.filter { course in
                // ✅ 修正：檢查所有時段（schedules），而不只是第一個時段
                // 課程的任一時段必須匹配目標的星期和節次
                let hasMatchingSchedule = course.schedules.contains { schedule in
                    schedule.dayOfWeek == timeSlot.dayOfWeek && schedule.periods.contains(timeSlot.period)
                }
                
                if !hasMatchingSchedule {
                    return false
                }
                
                // 不能與現有課程衝突
                // ✅ 修正：檢查所有時段是否有衝突
                let hasConflict = existingCourses.contains { existing in
                    // 檢查新課程的所有時段是否與現有課程的所有時段衝突
                    for newSchedule in course.schedules {
                        for existingSchedule in existing.schedules {
                            if newSchedule.dayOfWeek == existingSchedule.dayOfWeek &&
                               !Set(newSchedule.periods).intersection(Set(existingSchedule.periods)).isEmpty {
                                return true
                            }
                        }
                    }
                    return false
                }
                
                let isCompatible = !hasConflict
                if isCompatible {
                    // 找到匹配的時段用於 log
                    if let matchingSchedule = course.schedules.first(where: { $0.dayOfWeek == timeSlot.dayOfWeek && $0.periods.contains(timeSlot.period) }) {
                        print("✅ [updateDisplayCourses] Compatible course: \(course.name) - Day:\(matchingSchedule.dayOfWeek) Periods:\(matchingSchedule.periods)")
                    }
                }
                
                return isCompatible
            }
            
            print("🎯 [updateDisplayCourses] After FORCE timeSlot filtering: \(courses.count) courses")
        } else {
            print("📝 [updateDisplayCourses] No timeSlot, showing all courses")
            courses = allCourses
        }
        
        // Step 2: 應用其他搜尋和篩選條件
        if !searchText.isEmpty {
            courses = courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                course.dept.localizedCaseInsensitiveContains(searchText) ||
                (course.instructor?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let department = selectedDepartment {
            courses = courses.filter { $0.dept == department }
        }
        
        if let requiredType = selectedRequiredType {
            courses = courses.filter { $0.requiredType == requiredType }
        }
        
        if let grade = selectedGrade {
            courses = courses.filter { $0.grade == grade }
        }
        
        // ✅ 修正：檢查所有時段，不只是第一個
        if let dayOfWeek = selectedDayOfWeek {
            courses = courses.filter { course in
                course.schedules.contains { $0.dayOfWeek == dayOfWeek }
            }
        }
        
        print("🔍 [updateDisplayCourses] Final display courses: \(courses.count)")
        displayCourses = courses
    }
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                timeSlotHeaderView
                searchBarView
                
                courseContentView
            }
            .navigationTitle("選擇課程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            // ✅ 修正：使用 .task 確保在視圖準備好後立即載入資料
            .task {
                print("🚀 CoursePickerView task - Initial course update")
                // 確保只初始化一次
                guard !hasInitialized else { return }
                hasInitialized = true
                
                // 給 SwiftUI 一點時間完成視圖建構
                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
                
                await MainActor.run {
                updateDisplayCourses()
                
                if let timeSlot = timeSlot {
                    print("🎯 CoursePickerView opened for \(timeSlot.displayDay) 第\(timeSlot.period)節")
                    print("🎯 Found \(displayCourses.count) compatible courses")
                } else {
                    print("📝 CoursePickerView opened (no timeSlot)")
                    print("📝 Showing \(displayCourses.count) total courses")
                    }
                }
            }
            .onChange(of: searchText) { _, _ in updateDisplayCourses() }
            .onChange(of: selectedDepartment) { _, _ in updateDisplayCourses() }
            .onChange(of: selectedRequiredType) { _, _ in updateDisplayCourses() }
            .onChange(of: selectedGrade) { _, _ in updateDisplayCourses() }
            .onChange(of: courseDataStore.allCourses) { _, _ in updateDisplayCourses() }
        }
    }
    
    @ViewBuilder
    private var timeSlotHeaderView: some View {
        if let timeSlot = timeSlot {
            VStack(spacing: 4) {
                HStack {
                    Text("\(timeSlot.displayDay) 第\(timeSlot.period)節")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(displayCourses.count) 門課程")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let dept = selectedDepartment {
                    HStack {
                        Text("系所：\(dept)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("搜尋課程名稱、系所或教師", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var filterScrollView: some View {
        VStack(spacing: 8) {
            // 系所選單 - 佔滿整個橫排
            FilterDropdownMenu(
                title: "系所",
                selectedValue: selectedDepartment,
                placeholder: "選擇系所",
                icon: "building.2"
            ) {
                Button("全部系所") {
                    selectedDepartment = nil
                }
                
                Divider()
                
                ForEach(availableDepartments, id: \.self) { dept in
                    Button(dept) {
                        selectedDepartment = dept
                    }
                }
            }
            
            // 課程類型選單 - 佔滿整個橫排
            FilterDropdownMenu(
                title: "課程類型",
                selectedValue: selectedRequiredType?.displayName,
                placeholder: "選擇課程類型",
                icon: "doc.text"
            ) {
                Button("全部類型") {
                    selectedRequiredType = nil
                }
                
                Divider()
                
                ForEach(Course.RequiredType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        selectedRequiredType = type
                    }
                }
            }
            
            // 年級選單 - 佔滿整個橫排
            FilterDropdownMenu(
                title: "年級",
                selectedValue: selectedGrade != nil ? "\(selectedGrade!)" : nil,
                placeholder: "選擇年級",
                icon: "graduationcap"
            ) {
                Button("全部年級") {
                    selectedGrade = nil
                }
                
                Divider()
                
                ForEach(1...4, id: \.self) { grade in
                    Button("\(grade)") {
                        selectedGrade = grade
                    }
                }
            }
            
            // 清除篩選按鈕（如果有篩選條件的話）
            if hasActiveFilters {
                HStack {
                    Spacer()
                    Button(action: clearAllFilters) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                            Text("重置篩選")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.gray.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var courseContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                filterScrollView
                
                Divider()
                    .padding(.top, 8)
                
                if courseDataStore.isLoading {
                    loadingViewContent
                } else if let errorMessage = courseDataStore.errorMessage {
                    errorViewContent(errorMessage)
                } else if displayCourses.isEmpty {
                    emptyStateViewContent
                } else {
                    courseListViewContent
                }
            }
        }
    }
    
    private var loadingViewContent: some View {
        VStack(spacing: 16) {
            ProgressView("載入課程資料中...")
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
    }
    
    private func errorViewContent(_ errorMessage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(NCHUColors.warning)
            
            Text(errorMessage)
                .font(.headline)
            
            Button("重新載入") {
                courseDataStore.loadCourses()
            }
            .buttonStyle(.bordered)
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyStateViewContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text(timeSlot != nil ? "沒有可加入此時段的課程" : "找不到符合條件的課程")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(timeSlot != nil ? "所有課程都會與此時段或現有課程衝突" : "請調整搜尋或篩選條件")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                VStack(spacing: 8) {
                    if let dept = selectedDepartment {
                        Text("已篩選系所：\(dept)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("清除篩選條件") {
                        clearAllFilters()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var courseListViewContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(displayCourses) { course in
                VStack(spacing: 0) {
                    CourseRowView(course: course) {
                        onCourseSelected(course)
                        dismiss()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    if course.id != displayCourses.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var hasActiveFilters: Bool {
        selectedDepartment != nil || selectedRequiredType != nil || selectedGrade != nil || selectedDayOfWeek != nil
    }
    
    private func clearAllFilters() {
        selectedDepartment = nil
        selectedRequiredType = nil
        selectedGrade = nil
        selectedDayOfWeek = nil
    }
    
    private func dayName(_ day: Int) -> String {
        switch day {
        case 1: return "星期一"
        case 2: return "星期二"
        case 3: return "星期三"
        case 4: return "星期四"
        case 5: return "星期五"
        case 6: return "星期六"
        case 7: return "星期日"
        default: return "未知"
        }
    }
}

// MARK: - Filter UI Components

struct FilterDropdownMenu<Content: View>: View {
    let title: String
    let selectedValue: String?
    let placeholder: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(selectedValue != nil ? theme.accent.color : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(selectedValue ?? placeholder)
                        .font(.subheadline)
                        .fontWeight(selectedValue != nil ? .medium : .regular)
                        .foregroundStyle(selectedValue != nil ? .primary : .secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedValue != nil ? theme.accent.color.opacity(0.3) : .clear, lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
        .menuOrder(.fixed)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? theme.accent.color : .gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Course Row View

struct CourseRowView: View {
    let course: Course
    let onTap: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(deptWithGradeText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(course.requiredType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(typeColor.opacity(0.2))
                            .foregroundStyle(typeColor)
                            .clipShape(Capsule())
                        
                        if let credits = course.credits {
                            Text("\(credits) 學分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                HStack {
                    Label(timeDisplayText, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !course.buildingCode.isEmpty || !course.room.isEmpty {
                        Label(locationText, systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let instructor = course.instructor, !instructor.isEmpty {
                    Label(instructor, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var deptWithGradeText: String {
        if let grade = course.grade {
            return "\(course.dept) • \(grade)年級"
        } else {
            return course.dept
        }
    }
    
    private var typeColor: Color {
        return NCHUColors.courseTypeColor(for: course.requiredType, theme: theme)
    }
    
    private var timeDisplayText: String {
        if course.isMultiDayCourse {
            // 跨天課程：顯示完整時段信息
            return course.allSchedulesDescription
        } else {
            // 單天課程：使用簡化顯示
            let dayName = switch course.dayOfWeek {
            case 1: "週一"
            case 2: "週二"
            case 3: "週三"
            case 4: "週四"
            case 5: "週五"
            case 6: "週六"
            case 7: "週日"
            default: "未知"
            }
            
            let periodsText = course.periods.map(String.init).joined(separator: ",")
            return "\(dayName) 第\(periodsText)節"
        }
    }
    
    private var locationText: String {
        let building = course.buildingCode.isEmpty ? "" : course.buildingCode
        let room = course.room.isEmpty ? "" : course.room
        
        if !building.isEmpty && !room.isEmpty {
            return "\(building) \(room)"
        } else if !building.isEmpty {
            return building
        } else if !room.isEmpty {
            return room
        } else {
            return "未指定"
        }
    }
}



#Preview {
    NavigationView {
        CoursePickerView(
            timeSlot: TimeSlot(dayOfWeek: 1, period: 3),
            existingCourses: [],
            onCourseSelected: { course in
                print("Selected course: \(course.name)")
            }
        )
    }
    .environmentObject(ThemeManager())
}
