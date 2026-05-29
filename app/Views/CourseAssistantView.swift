//
//  CourseAssistantView.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

struct CourseAssistantView: View {
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject private var scheduleVM: ScheduleVM
    @ObservedObject private var userProfile: UserProfileManager
    
    init(scheduleVM: ScheduleVM) {
        self.scheduleVM = scheduleVM
        self.userProfile = UserProfileManager.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 個人資訊
                    userInfoSection
                    
                    // 通識推薦
                    generalEducationRecommendationSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("排課小幫手")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 個人資訊區塊
    
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("個人資訊")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // 系所資訊
                HStack {
                    Text(userProfile.profile.department)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemGroupedBackground))
                
                Divider()
                    .padding(.leading, 16)
                
                // 年級資訊
                HStack {
                    Text(userProfile.profile.grade)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if userProfile.profile.department == "請選擇系所" || userProfile.profile.grade == "請選擇年級" {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(NCHUColors.warning)
                    Text("請先在個人資料中設定您的系所和年級")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.leading, 4)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - 通識推薦區塊
    
    private var generalEducationRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("通識推薦")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // 智慧排課 - 根據空堂時間推薦
                NavigationLink(destination: SmartCourseRecommendationView(scheduleVM: scheduleVM)) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(NCHUColors.success.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(NCHUColors.success)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("空堂排課")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text("輸入空堂時間，自動篩選可選的通識課程")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .contentShape(Rectangle())
                }
                
                Divider()
                    .padding(.leading, 16)
                
                // 瀏覽通識課程
                NavigationLink(destination: GeneralEducationCoursesView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(theme.accent.color.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "book.fill")
                                .font(.title3)
                                .foregroundStyle(theme.accent.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("瀏覽通識課程")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text("查看所有通識課程，瀏覽課程大綱與詳細資訊")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .contentShape(Rectangle())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}


// MARK: - Extension for Course

extension Course {
    var timeDisplayString: String {
        if periods.isEmpty || dayOfWeek == 0 {
            return "時間未定"
        }
        
        let dayName = switch dayOfWeek {
        case 1: "週一"
        case 2: "週二"
        case 3: "週三"
        case 4: "週四"
        case 5: "週五"
        case 6: "週六"
        case 7: "週日"
        default: "未知"
        }
        
        let periodsText = periods.sorted().map(String.init).joined(separator: ",")
        return "\(dayName) 第\(periodsText)節"
    }
}

// MARK: - Preview

#Preview {
    CourseAssistantView(scheduleVM: ScheduleVM())
        .environmentObject(ThemeManager())
}
