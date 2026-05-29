//
//  GeneralEducationCoursesView.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/10/12.
//

import SwiftUI

struct GeneralEducationCoursesView: View {
    @StateObject private var courseStore = CourseDataStore.shared
    @State private var searchText = ""
    @State private var courseDetailItem: Course?  // ✅ 改用 item-based sheet 避免時序問題
    
    private var filteredCourses: [Course] {
        let genEdCourses = courseStore.allCourses.filter { $0.requiredType == Course.RequiredType.通識 }
        
        if searchText.isEmpty {
            return genEdCourses
        } else {
            return genEdCourses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                course.dept.localizedCaseInsensitiveContains(searchText) ||
                (course.instructor?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if courseStore.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("載入通識課程中...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredCourses.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text(searchText.isEmpty ? "暫無通識課程" : "找不到相關課程")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        if !searchText.isEmpty {
                            Text("試試調整搜尋關鍵字")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Course List
                    List(filteredCourses) { course in
                        GeneralEducationCourseRow(course: course) {
                            // ✅ 直接設定 course 作為 item
                            courseDetailItem = course
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color(.systemBackground))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("通識課程")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if courseStore.allCourses.isEmpty {
                    courseStore.loadCourses()
                }
            }
            // ✅ 使用 sheet(item:) 確保 course 在 sheet 顯示時已經是正確的值
            .sheet(item: $courseDetailItem) { course in
                CourseDetailView(course: course)
            }
        }
    }
}

// MARK: - Search Bar Component

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("搜尋課程名稱、系所或教師", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Course Row Component

struct GeneralEducationCourseRow: View {
    let course: Course
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Course Title and Department
                HStack {
                    Text(course.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Text(course.dept)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBlue).opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                
                // Schedule Information
                if !course.periods.isEmpty {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(weekdayName(course.dayOfWeek))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(course.periodsString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Location and Instructor
                HStack {
                    if !course.locationDescription.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(course.locationDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let instructor = course.instructor, !instructor.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(instructor)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let credits = course.credits {
                        Text("\(credits)學分")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGreen).opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                
                // Syllabus Indicator
                if course.hasSyllabus {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("查看課程大綱")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func weekdayName(_ dayOfWeek: Int) -> String {
        let weekdays = ["", "週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        return weekdays.indices.contains(dayOfWeek) ? weekdays[dayOfWeek] : "未定"
    }
}

#Preview {
    GeneralEducationCoursesView()
        .environmentObject(ThemeManager())
}
