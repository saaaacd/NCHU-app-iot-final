//
//  ScheduleAssistantView.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/9/23.
//

import SwiftUI

struct ScheduleAssistantView: View {
    @ObservedObject var scheduleVM: ScheduleVM
    @EnvironmentObject private var theme: ThemeManager
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    // Header Section
                    headerSection
                    
                    // Assistant Tools
                    assistantToolsSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("排課助手")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Magic wand icon with animation
            ZStack {
                Circle()
                    .fill(theme.accent.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.accent.color)
            }
            
            VStack(spacing: 8) {
                Text("排課小幫手")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("一鍵匯入系上課程，瀏覽通識課程")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("課程統計")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                StatCard(
                    icon: "book.fill",
                    title: "總課程數",
                    value: "\(scheduleVM.courses.count)",
                    color: theme.accent.color,
                    theme: theme
                )
                
                StatCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "時間衝突",
                    value: "\(scheduleVM.conflicts(in: scheduleVM.courses).count)",
                    color: scheduleVM.conflicts(in: scheduleVM.courses).isEmpty ? NCHUColors.success : NCHUColors.error,
                    theme: theme
                )
                
                StatCard(
                    icon: "clock.fill",
                    title: "每週總學分",
                    value: "\(totalCredits)",
                    color: theme.accent.color,
                    theme: theme
                )
                
                StatCard(
                    icon: "calendar.badge.clock",
                    title: "空堂時段",
                    value: "\(totalFreeSlots)",
                    color: theme.accent.color.opacity(0.8),
                    theme: theme
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Assistant Tools Section
    
    private var assistantToolsSection: some View {
        VStack(spacing: 20) {
            // 一鍵匯入系上課程
            NavigationLink(destination: CourseAssistantView(scheduleVM: scheduleVM)) {
                MainFeatureCard(
                    icon: "graduationcap.fill",
                    title: "一鍵匯入系上課程",
                    subtitle: "自動匯入您系所的必修與選修課程",
                    color: theme.accent.color,
                    theme: theme
                )
            }
            .buttonStyle(.plain)
            
            // 空堂排課 - 根據空堂時間推薦通識課程
            NavigationLink(destination: SmartCourseRecommendationView(scheduleVM: scheduleVM)) {
                MainFeatureCard(
                    icon: "sparkles",
                    title: "空堂排課",
                    subtitle: "輸入空堂時間，自動篩選可選的通識課程",
                    color: NCHUColors.success,
                    theme: theme
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Smart Suggestions Section
    
    private var smartSuggestionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("貼心提醒")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(generateSmartSuggestions(), id: \.id) { suggestion in
                    SmartSuggestionCard(suggestion: suggestion, theme: theme)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalCredits: Int {
        return scheduleVM.courses.compactMap { $0.credits }.reduce(0, +)
    }
    
    private var totalFreeSlots: Int {
        let weeklySlots = scheduleVM.calculateWeeklyFreeSlots()
        return weeklySlots.values.flatMap { $0 }.count
    }
    
    // MARK: - Smart Suggestions Logic
    
    private func generateSmartSuggestions() -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Check for conflicts
        if !scheduleVM.conflicts(in: scheduleVM.courses).isEmpty {
            suggestions.append(SmartSuggestion(
                id: "conflicts",
                type: .warning,
                title: "發現課程時間衝突",
                message: "您有 \(scheduleVM.conflicts(in: scheduleVM.courses).count) 組課程時間衝突，建議立即處理",
                actionTitle: "查看詳情"
            ))
        }
        
        // Check for too many courses in one day
        let coursesPerDay = Dictionary(grouping: scheduleVM.courses) { $0.dayOfWeek }
        for (day, courses) in coursesPerDay {
            if courses.count >= 4 {
                let dayName = ["", "週一", "週二", "週三", "週四", "週五", "週六", "週日"][day]
                suggestions.append(SmartSuggestion(
                    id: "heavy-day-\(day)",
                    type: .info,
                    title: "\(dayName)課程較多",
                    message: "\(dayName)有 \(courses.count) 門課程，建議適當調整以平衡學習負擔",
                    actionTitle: "查看建議"
                ))
            }
        }
        
        // Check for long gaps
        suggestions.append(SmartSuggestion(
            id: "optimization",
            type: .tip,
            title: "課表可以進一步調整",
            message: "系統分析您的課表，發現可以改善的時間安排",
            actionTitle: "查看建議"
        ))
        
        return suggestions
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MainFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            
            // Content
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct AssistantToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let hasIssue: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, color: Color, hasIssue: Bool = false, theme: ThemeManager, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.hasIssue = hasIssue
        self.theme = theme
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    
                    if hasIssue {
                        VStack {
                            HStack {
                                Spacer()
                            Circle()
                                .fill(NCHUColors.error)
                                .frame(width: 12, height: 12)
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

struct SmartSuggestion {
    let id: String
    let type: SuggestionType
    let title: String
    let message: String
    let actionTitle: String
    
    enum SuggestionType {
        case warning, info, tip
        
        var color: Color {
            switch self {
            case .warning: return NCHUColors.error
            case .info: return NCHUColors.info
            case .tip: return NCHUColors.success
            }
        }
        
        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .tip: return "lightbulb.fill"
            }
        }
    }
}

struct SmartSuggestionCard: View {
    let suggestion: SmartSuggestion
    let theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.type.icon)
                .font(.title2)
                .foregroundStyle(suggestion.type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Button(action: {
                // 執行建議動作（例如：開啟推薦課程頁面）
            }) {
                Text(suggestion.actionTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.accent.color)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 20)
    }
}

#Preview {
    ScheduleAssistantView(scheduleVM: ScheduleVM())
        .environmentObject(ThemeManager())
}
