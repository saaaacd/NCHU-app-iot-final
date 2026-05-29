//
//  CourseFormView.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/9/23.
//

import SwiftUI

struct CourseFormView: View {
    let course: Course?
    let timeSlot: TimeSlot?
    let onSave: (Course) -> Void
    let onDelete: ((Course) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var name: String = ""
    @State private var dept: String = ""
    @State private var selectedRequiredType: Course.RequiredType = .必修
    @State private var dayOfWeek: Int = 1
    @State private var selectedPeriods: Set<Int> = []
    @State private var grade: Int? = nil
    @State private var buildingCode: String = ""
    @State private var room: String = ""
    @State private var instructor: String = ""
    @State private var credits: String = ""
    @State private var courseNumber: String = ""
    
    private var isEditing: Bool {
        return course != nil
    }
    
    private var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !dept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !selectedPeriods.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Course Info
                Section("課程基本資訊") {
                    TextField("課程名稱", text: $name)
                    TextField("開課系所", text: $dept)
                    
                    Picker("課程類型", selection: $selectedRequiredType) {
                        ForEach(Course.RequiredType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("年級")
                        Spacer()
                        Picker("年級", selection: $grade) {
                            Text("不分年級").tag(nil as Int?)
                            Text("大一").tag(1 as Int?)
                            Text("大二").tag(2 as Int?)
                            Text("大三").tag(3 as Int?)
                            Text("大四").tag(4 as Int?)
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Time Schedule
                Section("上課時間") {
                    Picker("星期", selection: $dayOfWeek) {
                        Text("星期一").tag(1)
                        Text("星期二").tag(2)
                        Text("星期三").tag(3)
                        Text("星期四").tag(4)
                        Text("星期五").tag(5)
                        Text("星期六").tag(6)
                        Text("星期日").tag(7)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("節次 (可複選)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(1...14, id: \.self) { period in
                                PeriodToggleButton(
                                    period: period,
                                    isSelected: selectedPeriods.contains(period)
                                ) {
                                    if selectedPeriods.contains(period) {
                                        selectedPeriods.remove(period)
                                    } else {
                                        selectedPeriods.insert(period)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Location Info
                Section("上課地點") {
                    TextField("建築代號", text: $buildingCode)
                    TextField("教室", text: $room)
                }
                
                // Additional Info
                Section("其他資訊") {
                    TextField("授課教師", text: $instructor)
                    TextField("學分數", text: $credits)
                        .keyboardType(.numberPad)
                    TextField("選課號碼", text: $courseNumber)
                }
                
                // Delete button for editing
                if isEditing {
                    Section {
                        Button(role: .destructive, action: deleteCourse) {
                            Text("刪除課程")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "編輯課程" : "新增課程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveCourse()
                    }
                    .disabled(!isValid)
                    .foregroundStyle(isValid ? theme.accent.color : .secondary)
                }
            }
            .onAppear {
                loadCourseData()
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadCourseData() {
        if let existingCourse = course {
            // Load existing course data
            name = existingCourse.name
            dept = existingCourse.dept
            selectedRequiredType = existingCourse.requiredType
            dayOfWeek = existingCourse.dayOfWeek
            selectedPeriods = Set(existingCourse.periods)
            grade = existingCourse.grade
            buildingCode = existingCourse.buildingCode
            room = existingCourse.room
            instructor = existingCourse.instructor ?? ""
            credits = existingCourse.credits?.description ?? ""
            courseNumber = existingCourse.courseNumber ?? ""
        } else {
            // Initialize with time slot if provided
            if let timeSlot = timeSlot {
                dayOfWeek = timeSlot.dayOfWeek
                selectedPeriods = Set([timeSlot.period])
            }
        }
    }
    
    private func saveCourse() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDept = dept.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBuildingCode = buildingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRoom = room.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstructor = instructor.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCourseNumber = courseNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let creditValue = Int(credits.trimmingCharacters(in: .whitespacesAndNewlines))
        
        let newCourse: Course
        if let existingCourse = course {
            // Update existing course
            newCourse = Course(
                id: existingCourse.id,
                name: trimmedName,
                dept: trimmedDept,
                requiredType: selectedRequiredType,
                dayOfWeek: dayOfWeek,
                periods: Array(selectedPeriods).sorted(),
                grade: grade,
                buildingCode: trimmedBuildingCode,
                room: trimmedRoom,
                instructor: trimmedInstructor.isEmpty ? nil : trimmedInstructor,
                credits: creditValue,
                courseNumber: trimmedCourseNumber.isEmpty ? nil : trimmedCourseNumber
            )
        } else {
            // Create new course
            newCourse = Course(
                name: trimmedName,
                dept: trimmedDept,
                requiredType: selectedRequiredType,
                dayOfWeek: dayOfWeek,
                periods: Array(selectedPeriods).sorted(),
                grade: grade,
                buildingCode: trimmedBuildingCode,
                room: trimmedRoom,
                instructor: trimmedInstructor.isEmpty ? nil : trimmedInstructor,
                credits: creditValue,
                courseNumber: trimmedCourseNumber.isEmpty ? nil : trimmedCourseNumber
            )
        }
        
        onSave(newCourse)
        dismiss()
    }
    
    private func deleteCourse() {
        guard let course = course else { return }
        onDelete?(course)
        dismiss()
    }
}

// MARK: - Period Toggle Button

struct PeriodToggleButton: View {
    let period: Int
    let isSelected: Bool
    let onToggle: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Button(action: onToggle) {
            Text("\(period)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 32, height: 32)
                .background(isSelected ? theme.accent.color : .gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("New Course") {
    CourseFormView(
        course: nil,
        timeSlot: nil,
        onSave: { _ in },
        onDelete: nil
    )
    .environmentObject(ThemeManager())
}

#Preview("Edit Course") {
    CourseFormView(
        course: Course.sampleCourses[0],
        timeSlot: nil,
        onSave: { _ in },
        onDelete: { _ in }
    )
    .environmentObject(ThemeManager())
}
