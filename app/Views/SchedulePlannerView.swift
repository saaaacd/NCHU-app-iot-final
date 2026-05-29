//
//  SchedulePlannerView.swift
//  初興 (NCHUHelper)
//
//  Created by 劉李陽 on 2025/9/21.
//

import SwiftUI

// MARK: - TimeSlot Helper

struct TimeSlot {
    let dayOfWeek: Int  // 1=Mon, 2=Tue, etc.
    let period: Int     // 1-14
    
    var displayDay: String {
        switch dayOfWeek {
        case 1: return "星期一"
        case 2: return "星期二"
        case 3: return "星期三"
        case 4: return "星期四"
        case 5: return "星期五"
        default: return "未知"
        }
    }
}

// MARK: - Course Block Data Structure
struct CourseBlock: Identifiable, Hashable {
    let id = UUID()
    let course: Course
    let startPeriod: Int
    let endPeriod: Int
    let day: Int
    
    var height: Int {
        endPeriod - startPeriod + 1
    }
}

enum ScheduleViewMode {
    case grid, list
}

// ✅ 修正：用於解決 sheet 顯示時 timeSlot 還沒更新的問題
struct CoursePickerItem: Identifiable {
    let id = UUID()
    let timeSlot: TimeSlot?
}

// ✅ 修正：用於解決 sheet 顯示時 editingCourse 還沒更新的問題
struct CourseFormItem: Identifiable {
    let id = UUID()
    let course: Course?
    let timeSlot: TimeSlot?
}

struct SchedulePlannerView: View {
    @ObservedObject var scheduleVM: ScheduleVM
    @State private var courseFormItem: CourseFormItem?  // ✅ 改用 item-based sheet
    @State private var coursePickerItem: CoursePickerItem?  // ✅ 改用 item-based sheet
    @State private var viewMode: ScheduleViewMode = .grid
    
    // Default initializer for when no ScheduleVM is provided
    init(scheduleVM: ScheduleVM? = nil) {
        if let provided = scheduleVM {
            self.scheduleVM = provided
        } else {
            self.scheduleVM = ScheduleVM()
        }
    }
    
    // Convenience computed property for compatibility
    private var viewModel: ScheduleVM {
        return scheduleVM
    }
    @State private var courseDetailItem: Course?  // ✅ 改用 item-based sheet，Course 本身就是 Identifiable
    @State private var isEditMode = false
    @State private var showingClearConfirmation = false
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toolbar
                toolbarSection
                
                // Main Content - Grid or List View
                if viewMode == .grid {
                    // Grid View (Original Timetable)
                    ScrollView(.vertical, showsIndicators: false) {
                        TimetableGridView(
                            courses: viewModel.courses,
                            isEditMode: isEditMode,
                            theme: theme,
                            onTimeSlotTap: { timeSlot in
                                // 總是允許點擊空白時間格添加課程
                                print("🎯 [SchedulePlanner] Time slot tapped: \(timeSlot.displayDay) 第\(timeSlot.period)節")
                                // ✅ 修正：直接建立包含 timeSlot 的 item，確保 sheet 顯示時資料正確
                                coursePickerItem = CoursePickerItem(timeSlot: timeSlot)
                                print("🎯 [SchedulePlanner] Created CoursePickerItem with timeSlot")
                            },
                            onCourseTap: { course in
                                if isEditMode {
                                    // ✅ 修正：直接建立包含 course 的 item
                                    courseFormItem = CourseFormItem(course: course, timeSlot: nil)
                                } else {
                                    // ✅ 修正：直接設定 course 作為 item
                                    courseDetailItem = course
                                }
                            }
                        )
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List View
                    ScheduleListView(
                        courses: viewModel.courses,
                        isEditMode: isEditMode,
                        theme: theme,
                        onCourseTap: { course in
                            if isEditMode {
                                // ✅ 修正：直接建立包含 course 的 item
                                courseFormItem = CourseFormItem(course: course, timeSlot: nil)
                            } else {
                                // ✅ 修正：直接設定 course 作為 item
                                courseDetailItem = course
                            }
                        },
                        onAddCourse: {
                            // ✅ 修正：從列表添加課程時不指定時間槽
                            coursePickerItem = CoursePickerItem(timeSlot: nil)
                        }
                    )
                }
            }
            .navigationTitle("114-1課表")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ 修正：使用 sheet(item:) 確保 course 和 timeSlot 在 sheet 顯示時已經是正確的值
            .sheet(item: $courseFormItem) { item in
                CourseFormView(
                    course: item.course,
                    timeSlot: item.timeSlot,
                    onSave: { course in
                        if let editingCourse = item.course {
                            viewModel.updateCourse(editingCourse, with: course)
                        } else {
                            viewModel.addCourse(course)
                        }
                    },
                    onDelete: { course in
                        viewModel.removeCourse(withID: course.id)
                    }
                )
            }
            // ✅ 修正：使用 sheet(item:) 確保 timeSlot 在 sheet 顯示時已經是正確的值
            .sheet(item: $coursePickerItem) { item in
                CoursePickerView(
                    timeSlot: item.timeSlot,  // ✅ 使用 item 中捕獲的 timeSlot
                    existingCourses: viewModel.courses,
                    onCourseSelected: { selectedCourse in
                        print("🎯 [SchedulePlanner] Course selected with timeSlot: \(String(describing: item.timeSlot))")
                        // 創建新的課程實例以避免 ID 衝突，但保持原本的完整時間結構
                        let courseToAdd = Course(
                            id: UUID(),
                            name: selectedCourse.name,
                            dept: selectedCourse.dept,
                            requiredType: selectedCourse.requiredType,
                            schedules: selectedCourse.schedules,  // ✅ 保持完整的多時段結構
                            grade: selectedCourse.grade,
                            buildingCode: selectedCourse.buildingCode,
                            room: selectedCourse.room,
                            instructor: selectedCourse.instructor,
                            credits: selectedCourse.credits,
                            courseNumber: selectedCourse.courseNumber
                        )
                        viewModel.addCourse(courseToAdd)
                    }
                )
                .environmentObject(theme)
            }
            // ✅ 修正：使用 sheet(item:) 確保 course 在 sheet 顯示時已經是正確的值
            .sheet(item: $courseDetailItem) { course in
                    CourseDetailView(
                    course: course,
                    onEdit: { updatedCourse in
                        viewModel.updateCourse(course, with: updatedCourse)
                        },
                    onDelete: { deletedCourse in
                        viewModel.removeCourse(withID: deletedCourse.id)
                        }
                    )
            }
            .alert("清空所有課程", isPresented: $showingClearConfirmation) {
                Button("取消", role: .cancel) { }
                Button("確定清空", role: .destructive) {
                    viewModel.clearAllCourses()
                }
            } message: {
                Text("確定要清空所有課程嗎？此操作無法復原。")
            }
        }
    }
    
    // MARK: - Toolbar Section
    
    private var toolbarSection: some View {
        VStack(spacing: 8) {
            // Main action buttons
            HStack {
                // Edit mode toggle button
                Group {
                    if isEditMode {
                        Button(action: {
                            isEditMode.toggle()
                        }) {
                            Label("完成編輯", systemImage: "checkmark")
                        }
                        .buttonStyle(BorderedButtonStyle())
                               .foregroundColor(theme.accent.color)
                    } else {
                        Button(action: {
                            isEditMode.toggle()
                        }) {
                            Label("編輯課表", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                }
                .controlSize(.small)
                
                Spacer()
                
                // View mode toggle
                HStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewMode = .grid
                        }
                    }) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(viewMode == .grid ? theme.accent.color : .secondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewMode = .list
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundStyle(viewMode == .list ? theme.accent.color : .secondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .opacity(0.8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
                
                // Clear all button
                Button(action: {
                    showingClearConfirmation = true
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.small)
                .disabled(viewModel.courses.isEmpty)
            }
            
            // Usage hint
            if !viewModel.courses.isEmpty {
                HStack {
                    Image(systemName: isEditMode ? "square.and.pencil" : "hand.tap")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text(getUsageHintText())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.regularMaterial)
                .opacity(0.85)
        )
    }
    
    private func getUsageHintText() -> String {
        if isEditMode {
            return viewMode == .grid ? "點選空格或課程進行編輯" : "點選 + 新增課程，點選課程編輯"
        } else {
            return viewMode == .grid ? "點選空格新增課程，點選課程查看詳情" : "點選課程查看詳情和大綱"
        }
    }
}

// MARK: - Timetable Grid View

struct TimetableGridView: View {
    let courses: [Course]
    let isEditMode: Bool
    let theme: ThemeManager
    let onTimeSlotTap: (TimeSlot) -> Void
    let onCourseTap: (Course) -> Void
    
    private let dayHeaders = ["一", "二", "三", "四", "五"]
    private let periods = 1...14
    private let cellHeight: CGFloat = 55
    private let timeColumnWidth: CGFloat = 50
    
    private func cellWidth(for availableWidth: CGFloat) -> CGFloat {
        // 計算每個日期欄的寬度：總寬度減去時間欄寬度，再除以5天，再減去間距
        let totalSpacing: CGFloat = 6 // 5個間距，每個1點
        let availableForCells = availableWidth - timeColumnWidth - totalSpacing - 8 // 8是padding
        return max(65, availableForCells / 5) // 最小寬度65
    }
    
    var body: some View {
        VStack(spacing: 1) {
            // Header row with days
            HStack(spacing: 1) {
                // Empty corner cell for time
                Text("時間")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .frame(width: timeColumnWidth, height: 35)
                    .background(.quaternary)
                
                ForEach(1...5, id: \.self) { day in
                    Text(dayHeaders[day - 1])
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, minHeight: 35)
                        .background(.tertiary)
                }
            }
            
            // Timetable content using ZStack for overlapping course blocks
            HStack(spacing: 1) {
                // Time column
                VStack(spacing: 1) {
                    ForEach(Array(periods), id: \.self) { period in
                        VStack(spacing: 2) {
                            Text("\(period)")
                                .font(.caption2)
                                .fontWeight(.medium)
                            Text(timeForPeriod(period))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: timeColumnWidth, height: cellHeight)
                        .background(.quaternary)
                    }
                }
                
                // Day columns with course blocks
                ForEach(1...5, id: \.self) { day in
                    dayColumn(for: day)
                }
            }
        }
        .background(.background)
        .cornerRadius(8)
    }
    
    /// 創建單個日期列
    private func dayColumn(for day: Int) -> some View {
        ZStack(alignment: .topLeading) {
            // 背景網格
            VStack(spacing: 1) {
                ForEach(Array(periods), id: \.self) { period in
                    EmptyTimeSlotCell(
                        period: period,
                        day: day,
                        isEditMode: isEditMode,
                        theme: theme,
                        onTimeSlotTap: {
                            onTimeSlotTap(TimeSlot(dayOfWeek: day, period: period))
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: cellHeight)
                }
            }
            
            // 課程區塊覆蓋層
            ForEach(createCourseBlocks(for: day)) { block in
                CourseBlockView(
                    block: block,
                    cellHeight: cellHeight,
                    isEditMode: isEditMode,
                    theme: theme,
                    onTap: { onCourseTap(block.course) }
                )
                .offset(y: CGFloat(block.startPeriod - 1) * (cellHeight + 1))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func coursesAt(day: Int, period: Int) -> [Course] {
        return courses.filter { course in
            // 檢查所有時段，而不只是第一個時段
            course.schedules.contains { schedule in
                schedule.dayOfWeek == day && schedule.periods.contains(period)
            }
        }
    }
    
    /// 為指定日期創建課程區塊
    private func createCourseBlocks(for day: Int) -> [CourseBlock] {
        // 找出該天有課的所有課程，檢查所有時段
        let daysCourses = courses.filter { course in
            course.schedules.contains { $0.dayOfWeek == day }
        }
        var blocks: [CourseBlock] = []
        
        for course in daysCourses {
            // 處理該課程在這一天的所有時段
            let daySchedules = course.schedules.filter { $0.dayOfWeek == day }
            
            for schedule in daySchedules {
                let sortedPeriods = schedule.periods.sorted()
                var currentBlock: [Int] = []
                
                for period in sortedPeriods {
                    if currentBlock.isEmpty || period == currentBlock.last! + 1 {
                        // 連續時段
                        currentBlock.append(period)
                    } else {
                        // 非連續，建立前一個區塊
                        if let start = currentBlock.first, let end = currentBlock.last {
                            blocks.append(CourseBlock(
                                course: course,
                                startPeriod: start,
                                endPeriod: end,
                                day: day
                            ))
                        }
                        currentBlock = [period]
                    }
                }
                
                // 建立最後一個區塊
                if let start = currentBlock.first, let end = currentBlock.last {
                    blocks.append(CourseBlock(
                        course: course,
                        startPeriod: start,
                        endPeriod: end,
                        day: day
                    ))
                }
            }
        }
        
        return blocks
    }
    
    private func timeForPeriod(_ period: Int) -> String {
        // NCHU 正確的課程時間表：
        // 第1節: 8:10, 第2節: 9:10, 第3節: 10:10, 第4節: 11:10
        // 第5節: 13:10 (下午1:10開始), 第6節: 14:10, ...
        
        switch period {
        case 1: return "8:10"
        case 2: return "9:10"
        case 3: return "10:10"
        case 4: return "11:10"
        case 5: return "13:10"  // 下午1:10開始
        case 6: return "14:10"
        case 7: return "15:10"
        case 8: return "16:10"
        case 9: return "17:10"
        case 10: return "18:10"
        case 11: return "19:10"
        case 12: return "20:10"
        case 13: return "21:10"
        case 14: return "22:10"
        default: return "時間未定"
        }
    }
}

// MARK: - Time Slot Cell

struct TimeSlotCell: View {
    let period: Int
    let day: Int
    let courses: [Course]
    let isEditMode: Bool
    let theme: ThemeManager
    let onTimeSlotTap: () -> Void
    let onCourseTap: (Course) -> Void
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(.background)
                .overlay(
                    Rectangle()
                        .stroke(.separator, lineWidth: 0.5)
                )
            
            if courses.isEmpty {
                // Empty slot - always tappable to add courses
                Button(action: onTimeSlotTap) {
                    Rectangle()
                        .fill(theme.accent.color.opacity(0.05)) // 總是顯示背景提示可點擊
                        .overlay(
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(theme.accent.color.opacity(isEditMode ? 0.6 : 0.3))
                                .font(.title2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Course(s) in this slot
                VStack(spacing: 2) {
                           ForEach(courses.prefix(2)) { course in
                               CourseCell(
                                   course: course,
                                   isEditMode: isEditMode,
                                   theme: theme,
                                   onTap: { onCourseTap(course) }
                               )
                           }
                    
                    if courses.count > 2 {
                        Text("+\(courses.count - 2)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Course Cell

struct CourseCell: View {
    let course: Course
    let isEditMode: Bool
    let theme: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 1) {
                // 課程名稱 - 顯示前幾個字
                Text(course.name.prefix(4) + (course.name.count > 4 ? "..." : ""))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                // 教室資訊
                if !course.room.isEmpty {
                    Text(course.room)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(courseColor.opacity(0.9))
                    .overlay(
                        // Edit mode indicator
                        isEditMode ? 
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.black.opacity(0.1))
                            )
                        : nil
                    )
            )
            .foregroundStyle(.white)
            .overlay(
                // Edit icon in top-right corner when in edit mode
                isEditMode ? 
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.3)))
                    }
                    Spacer()
                }
                .padding(2)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var courseColor: Color {
        return NCHUColors.courseTypeColor(for: course.requiredType, theme: theme)
    }
}

// MARK: - Empty Time Slot Cell

struct EmptyTimeSlotCell: View {
    let period: Int
    let day: Int
    let isEditMode: Bool
    let theme: ThemeManager
    let onTimeSlotTap: () -> Void
    
    var body: some View {
        Button(action: onTimeSlotTap) {
            Rectangle()
                .fill(
                    isEditMode ? 
                    theme.accent.color.opacity(0.05) :  // 編輯模式下顯示淺色背景
                    Color.clear                         // 非編輯模式下透明背景
                )
                .overlay(
                    Rectangle()
                        .stroke(.separator, lineWidth: 0.5)
                )
                .overlay(
                    // 只在編輯模式下顯示加號
                    isEditMode ? 
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.accent.color.opacity(0.6))
                        .font(.caption)
                    : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
        // 保持在兩種模式下都可點擊，符合使用提示的說明
    }
}

// MARK: - Course Block View

struct CourseBlockView: View {
    let block: CourseBlock
    let cellHeight: CGFloat
    let isEditMode: Bool
    let theme: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // 課程名稱
                Text(block.course.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 教室資訊
                if !block.course.locationDescription.isEmpty {
                    Text(block.course.locationDescription)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity)
            .frame(height: CGFloat(block.height) * cellHeight + CGFloat(block.height - 1))
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(courseColor.opacity(0.9))
                    .overlay(
                        isEditMode ?
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white, lineWidth: 1.5)
                        : nil
                    )
            )
            .overlay(
                // Edit icon in top-right corner when in edit mode
                isEditMode ?
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.3)))
                    }
                    Spacer()
                }
                .padding(4)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var courseColor: Color {
        return NCHUColors.courseTypeColor(for: block.course.requiredType, theme: theme)
    }
}

#Preview {
    NavigationView {
        SchedulePlannerView()
    }
}

// MARK: - Schedule List View

struct ScheduleListView: View {
    let courses: [Course]
    let isEditMode: Bool
    let theme: ThemeManager
    let onCourseTap: (Course) -> Void
    let onAddCourse: () -> Void
    
    private let weekdays = [
        (1, "週一"),
        (2, "週二"),
        (3, "週三"),
        (4, "週四"),
        (5, "週五"),
        (6, "週六"),
        (7, "週日")
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Add course button for edit mode
                if isEditMode {
                    addCourseButton
                }
                
                // Group courses by day
                // ✅ 修正：檢查所有時段（schedules），支援多時段課程
                ForEach(weekdays, id: \.0) { day, dayName in
                    let dayCourses = courses
                        .filter { course in
                            // 檢查任一時段是否在這一天
                            course.schedules.contains { $0.dayOfWeek == day }
                        }
                        .sorted { course1, course2 in
                            // 取得該天的最早節次來排序
                            let period1 = course1.schedules
                                .filter { $0.dayOfWeek == day }
                                .flatMap { $0.periods }
                                .min() ?? Int.max
                            let period2 = course2.schedules
                                .filter { $0.dayOfWeek == day }
                                .flatMap { $0.periods }
                                .min() ?? Int.max
                            return period1 < period2
                        }
                    
                    if !dayCourses.isEmpty {
                        DaySection(
                            dayName: dayName,
                            courses: dayCourses,
                            isEditMode: isEditMode,
                            theme: theme,
                            onCourseTap: onCourseTap
                        )
                    }
                }
                
                // Empty state
                if courses.isEmpty {
                    EmptyScheduleListView(theme: theme, onAddCourse: onAddCourse)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var addCourseButton: some View {
        Button(action: onAddCourse) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.accent.color)
                
                Text("新增課程")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// MARK: - Day Section

struct DaySection: View {
    let dayName: String
    let courses: [Course]
    let isEditMode: Bool
    let theme: ThemeManager
    let onCourseTap: (Course) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            HStack {
                Text(dayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("\(courses.count) 門課")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Courses for this day
            VStack(spacing: 6) {
                ForEach(courses) { course in
                    CourseListRowView(
                        course: course,
                        isEditMode: isEditMode,
                        theme: theme,
                        onTap: onCourseTap
                    )
                }
            }
        }
    }
}

// MARK: - Course List Row View

struct CourseListRowView: View {
    let course: Course
    let isEditMode: Bool
    let theme: ThemeManager
    let onTap: (Course) -> Void
    
    var body: some View {
        Button(action: { onTap(course) }) {
            HStack(spacing: 12) {
                // Time info
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.periodsString + "節")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accent.color)
                    
                    Text(timeRangeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 65, alignment: .leading)
                
                // Course details
                VStack(alignment: .leading, spacing: 4) {
                    // Course name and type
                    HStack {
                        Text(course.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(course.requiredType.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(courseTypeColor.opacity(0.2))
                            .foregroundStyle(courseTypeColor)
                            .clipShape(Capsule())
                    }
                    
                    // Location and instructor
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Text(course.locationDescription.isEmpty ? "教室未定" : course.locationDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let instructor = course.instructor, !instructor.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text(instructor)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Indicators
                        HStack(spacing: 6) {
                            if course.hasSyllabus {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                    .foregroundStyle(theme.accent.color.opacity(0.7))
                            }
                            
                            if let credits = course.credits {
                                Text("\(credits)學分")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Edit indicator
                if isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .opacity(0.85)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditMode ? theme.accent.color.opacity(0.3) : Color(.separator).opacity(0.5), lineWidth: isEditMode ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private var timeRangeString: String {
        guard let firstPeriod = course.periods.min(),
              let lastPeriod = course.periods.max() else {
            return ""
        }
        
        let startTime = periodToTimeString(firstPeriod)
        let endTime = periodToEndTimeString(lastPeriod)
        return "\(startTime)-\(endTime)"
    }
    
    private func periodToTimeString(_ period: Int) -> String {
        let startHour = 8
        let startMinute = 10
        let totalMinutes = startMinute + (period - 1) * 60
        let hour = startHour + totalMinutes / 60
        let minute = totalMinutes % 60
        return String(format: "%d:%02d", hour, minute)
    }
    
    private func periodToEndTimeString(_ period: Int) -> String {
        let startHour = 8
        let startMinute = 10
        let totalMinutes = startMinute + period * 60
        let hour = startHour + totalMinutes / 60
        let minute = totalMinutes % 60
        return String(format: "%d:%02d", hour, minute)
    }
    
    private var courseTypeColor: Color {
        return NCHUColors.courseTypeColor(for: course.requiredType, theme: theme)
    }
}

// MARK: - Empty Schedule List View

struct EmptyScheduleListView: View {
    let theme: ThemeManager
    let onAddCourse: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(theme.accent.color.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("還沒有課程")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("開始建立您的課表吧！")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onAddCourse) {
                HStack {
                    Image(systemName: "plus")
                    Text("新增第一門課程")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.accent.color)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Grid View") {
    NavigationView {
        SchedulePlannerView()
    }
    .environmentObject(ThemeManager())
}

#Preview("With Sample Courses") {
    let viewModel = ScheduleVM()
    viewModel.addCourses(Course.sampleCourses)
    
    return NavigationView {
        SchedulePlannerView(scheduleVM: viewModel)
    }
    .environmentObject(ThemeManager())
}
