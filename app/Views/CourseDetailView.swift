//
//  CourseDetailView.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/9/23.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var showingEditForm = false
    @State private var showingSyllabus = false
    
    var onEdit: ((Course) -> Void)?
    var onDelete: ((Course) -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Course Header
                    courseHeaderSection
                    
                    // Course Details
                    courseDetailsSection
                    
                    // Time and Location
                    timeLocationSection
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("課程詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if onEdit != nil {
                        Button("編輯") {
                            showingEditForm = true
                        }
                        .foregroundStyle(theme.accent.color)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            CourseFormView(
                course: course,
                timeSlot: nil,
                onSave: { updatedCourse in
                    onEdit?(updatedCourse)
                    showingEditForm = false
                },
                onDelete: { courseToDelete in
                    onDelete?(courseToDelete)
                    showingEditForm = false
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingSyllabus) {
            if let syllabusURL = course.syllabusURL {
                SimpleWebViewContainer(
                    url: syllabusURL,
                    title: "\(course.name) 課程大綱",
                    useSafari: true  // 課程大綱用 Safari 開啟
                )
            } else {
                // 防止空URL情況（理論上不應該發生，因為 hasSyllabus 已經檢查過）
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(NCHUColors.warning)
                    Text("課程大綱暫時無法載入")
                        .font(.headline)
                        .padding()
                    Button("關閉") {
                        showingSyllabus = false
                    }
                    .foregroundColor(theme.accent.color)
                }
                .padding()
            }
        }
        .alert("提示", isPresented: $showingError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Course Header Section
    
    private var courseHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Course name and type
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(deptWithGradeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Course type badge
                Text(course.requiredType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(courseTypeColor.opacity(0.2))
                    .foregroundStyle(courseTypeColor)
                    .clipShape(Capsule())
            }
            
            Divider()
        }
    }
    
    // MARK: - Course Details Section
    
    private var courseDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("課程資訊")
                .font(.headline)
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 12) {
                
                // Instructor
                DetailItemView(
                    icon: "person.circle",
                    title: "授課教師",
                    value: course.instructor ?? "未指定",
                    theme: theme
                )
                
                // Credits
                DetailItemView(
                    icon: "star.circle",
                    title: "學分數",
                    value: course.credits.map { "\($0)學分" } ?? "未指定",
                    theme: theme
                )
                
                // Course number
                if let courseNumber = course.courseNumber, !courseNumber.isEmpty {
                    DetailItemView(
                        icon: "number.circle",
                        title: "選課號碼",
                        value: courseNumber,
                        theme: theme
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Time and Location Section
    
    private var timeLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("時間地點")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Time
                HStack {
                    Image(systemName: "clock.circle")
                        .foregroundStyle(theme.accent.color)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("上課時間")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(course.timeDescription)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                // Location
                HStack {
                    Image(systemName: "location.circle")
                        .foregroundStyle(theme.accent.color)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("上課地點")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(course.locationDescription.isEmpty ? "未指定" : course.locationDescription)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // View Syllabus Button - 總是顯示，但根據是否有 courseNumber 來決定是否可用
            Button(action: {
                if course.hasSyllabus {
                    DispatchQueue.main.async {
                        showingSyllabus = true
                    }
                } else {
                    // 顯示提示：沒有選課號碼
                    errorMessage = "此課程沒有選課號碼，無法查看課程大綱"
                    showingError = true
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("查看課程大綱")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(course.hasSyllabus ? "開啟中興大學課程大綱頁面" : "此課程沒有選課號碼")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if course.hasSyllabus {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(course.hasSyllabus ? theme.accent.color.opacity(0.1) : Color(.systemGray5).opacity(0.5))
                .foregroundStyle(course.hasSyllabus ? theme.accent.color : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!course.hasSyllabus)
            
            // Additional Info
            if course.hasSyllabus {
                HStack(spacing: 12) {
                    // Quick info about syllabus
                    VStack(alignment: .leading, spacing: 4) {
                        Text("課程大綱資訊")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text("包含課程目標、教學內容、評分方式等詳細資訊")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            } else {
                // No course number available
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("此課程尚未提供選課號碼，因此無法查看線上課程大綱")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Helper Properties
    
    private var courseTypeColor: Color {
        return NCHUColors.courseTypeColor(for: course.requiredType, theme: theme)
    }
    
    private var deptWithGradeText: String {
        if let grade = course.grade {
            return "\(course.dept) • \(grade)年級"
        } else {
            return course.dept
        }
    }
}

// MARK: - Detail Item View

struct DetailItemView: View {
    let icon: String
    let title: String
    let value: String
    let theme: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(theme.accent.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview("Course Detail") {
    CourseDetailView(
        course: Course.sampleCourses[0],
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .environmentObject(ThemeManager())
}

#Preview("Course Detail - No Syllabus") {
    let courseWithoutSyllabus = Course(
        name: "測試課程",
        dept: "測試系所",
        requiredType: .選修,
        dayOfWeek: 1,
        periods: [1, 2],
        grade: 2,
        buildingCode: "測試館",
        room: "101",
        instructor: "測試老師",
        credits: 3,
        courseNumber: nil
    )
    
    CourseDetailView(
        course: courseWithoutSyllabus
    )
    .environmentObject(ThemeManager())
}
