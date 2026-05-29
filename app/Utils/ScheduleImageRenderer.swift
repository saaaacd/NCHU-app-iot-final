//
//  ScheduleImageRenderer.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/1/23.
//

import SwiftUI
import UIKit

/// 課表圖片渲染器
struct ScheduleImageRenderer {
    
    /// 將課表渲染為圖片
    static func renderScheduleImage(
        courses: [Course],
        theme: ThemeManager,
        size: CGSize,
        style: WallpaperStyle = .modern
    ) -> UIImage? {
        let view = ScheduleWallpaperView(
            courses: courses,
            theme: theme,
            style: style
        )
        .frame(width: size.width, height: size.height)
        
        return viewToImage(view: view, size: size)
    }
    
    /// 將 SwiftUI View 轉換為 UIImage
    private static func viewToImage(view: some View, size: CGSize) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
    }
}

/// 桌布樣式
enum WallpaperStyle: String, CaseIterable {
    case modern = "現代風格"
    case classic = "經典風格"
    case minimal = "極簡風格"
}

/// 課表桌布視圖
struct ScheduleWallpaperView: View {
    let courses: [Course]
    let theme: ThemeManager
    let style: WallpaperStyle
    
    private let dayHeaders = ["一", "二", "三", "四", "五"]
    private let periods = 1...14
    
    var body: some View {
        ZStack {
            // 背景
            backgroundView
            
            // 課表內容
            VStack(spacing: 0) {
                // 標題
                titleView
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                
                // 課表網格
                timetableGrid
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // 底部資訊
                footerView
                    .padding(.bottom, 40)
            }
        }
    }
    
    private var backgroundView: some View {
        Group {
            switch style {
            case .modern:
                LinearGradient(
                    colors: [
                        Color(white: 0.98),
                        Color(white: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .classic:
                Color.white
            case .minimal:
                Color(white: 0.99)
            }
        }
    }
    
    private var titleView: some View {
        VStack(spacing: 8) {
            Text("中興大學")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.accent.color)
            
            Text("課程表")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    
    private var timetableGrid: some View {
        VStack(spacing: 2) {
            // 標題行
            HStack(spacing: 2) {
                Text("時間")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 60, height: 40)
                    .background(theme.accent.color.opacity(0.2))
                    .foregroundStyle(theme.accent.color)
                    .cornerRadius(6)
                
                ForEach(1...5, id: \.self) { day in
                    Text(dayHeaders[day - 1])
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(theme.accent.color.opacity(0.15))
                        .foregroundStyle(theme.accent.color)
                        .cornerRadius(6)
                }
            }
            
            // 課表內容
            HStack(alignment: .top, spacing: 2) {
                // 時間欄
                VStack(spacing: 2) {
                    ForEach(Array(periods), id: \.self) { period in
                        Text("\(period)")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 60, height: 50)
                            .background(Color(white: 0.95))
                            .foregroundStyle(.secondary)
                            .cornerRadius(4)
                    }
                }
                
                // 日期欄
                ForEach(1...5, id: \.self) { day in
                    dayColumn(for: day)
                }
            }
        }
    }
    
    private func dayColumn(for day: Int) -> some View {
        ZStack(alignment: .top) {
            // 背景網格
            VStack(spacing: 2) {
                ForEach(Array(periods), id: \.self) { period in
                    Rectangle()
                        .fill(Color(white: 0.98))
                        .frame(height: 50)
                        .cornerRadius(4)
                }
            }
            
            // 課程區塊
            ForEach(createCourseBlocks(for: day)) { block in
                courseBlockView(block: block)
                    .offset(y: CGFloat(block.startPeriod - 1) * 52)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func courseBlockView(block: CourseBlock) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(block.course.name)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let instructor = block.course.instructor {
                Text(instructor)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .opacity(0.8)
            }
            
            Text(block.course.locationDescription)
                .font(.system(size: 8))
                .lineLimit(1)
                .opacity(0.7)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: CGFloat(block.height) * 50 - 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(courseColor(for: block.course))
        .foregroundStyle(.white)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func courseColor(for course: Course) -> Color {
        switch course.requiredType {
        case .必修:
            return theme.requiredCourseColor.color
        case .選修:
            return theme.electiveCourseColor.color
        case .通識:
            return theme.generalEducationColor.color
        }
    }
    
    private func createCourseBlocks(for day: Int) -> [CourseBlock] {
        let daysCourses = courses.filter { course in
            course.schedules.contains { $0.dayOfWeek == day }
        }
        var blocks: [CourseBlock] = []
        
        for course in daysCourses {
            let daySchedules = course.schedules.filter { $0.dayOfWeek == day }
            
            for schedule in daySchedules {
                let sortedPeriods = schedule.periods.sorted()
                guard let startPeriod = sortedPeriods.first,
                      let endPeriod = sortedPeriods.last else { continue }
                
                blocks.append(CourseBlock(
                    course: course,
                    startPeriod: startPeriod,
                    endPeriod: endPeriod,
                    day: day
                ))
            }
        }
        
        return blocks
    }
    
    private var footerView: some View {
        HStack {
            Spacer()
            Text("\(courses.count) 門課程")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

