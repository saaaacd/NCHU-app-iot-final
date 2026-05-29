//
//  MainTabView.swift
//  初興 (NCHUHelper)
//
//  Created by 劉李陽 on 2025/9/21.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var scheduleVM = ScheduleVM()  // 共享的課程資料
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 主畫面標籤
            HomeTabView(selectedTab: $selectedTab, scheduleVM: scheduleVM)
                .tabItem {
                    Image(systemName: "house")
                    Text("主畫面")
                }
                .tag(0)
            
            // 課表標籤
            SchedulePlannerView(scheduleVM: scheduleVM)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("課表")
                }
                .tag(1)
            
            // 排課助手標籤
            CourseAssistantView(scheduleVM: scheduleVM)
                .tabItem {
                    Image(systemName: "wand.and.stars")
                    Text("排課助手")
                }
                .tag(2)
            
            // 校園地圖標籤
            CampusSearchView()
                .tabItem {
                    Image(systemName: "map")
                    Text("校園地圖")
                }
                .tag(3)
            
            // 常用功能標籤
            UtilitiesView()
                .tabItem {
                    Image(systemName: "person")
                    Text("常用功能")
                }
                .tag(4)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCampusMap)) { notification in
            if let buildingCode = notification.userInfo?["buildingCode"] as? String {
                // Switch to campus map tab
                selectedTab = 3
                // Post another notification to the campus search view with the building code
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SearchBuildingInCampusMap"),
                        object: nil,
                        userInfo: ["buildingCode": buildingCode]
                    )
                }
            }
        }
    }
}

// MARK: - Home Tab View

struct HomeTabView: View {
    @Binding var selectedTab: Int
    @ObservedObject var scheduleVM: ScheduleVM
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var avatarManager = AvatarManager()
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingAvatarPicker = false
    
    // ✅ 雷點2&3修正：使用專門的 struct 來儲存 WebView 資訊
    // 這樣可以確保 sheet 顯示時，URL 和 title 一定是正確的值
    @State private var webViewItem: WebViewItem?
    @State private var showingCalendar = false
    @State private var showingAIAssistant = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Unified Scrollable Content
                ScrollView {
                LazyVStack(spacing: 12) {
                    // Header with Avatar and Profile (now scrollable)
                    VStack(spacing: 12) {
                        Button(action: {
                            showingAvatarPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: theme.accent.color.opacity(0.3), radius: 8)
                                
                                Circle()
                                    .stroke(theme.accent.color, lineWidth: 2)
                                    .frame(width: 80, height: 80)
                                
                                AvatarView(avatarManager.selectedAvatar, customImage: avatarManager.customAvatarImage, size: 74)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(spacing: 4) {
                            Text(profileManager.profile.name == "請設定姓名" ? profileManager.profile.name : "\(profileManager.profile.name.prefix(1))同學")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(profileManager.profile.department)・\(profileManager.profile.grade)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 0)
                    
                    // 我的課程區塊
                    MyCoursesSection(scheduleVM: scheduleVM, selectedTab: $selectedTab)  // ✅ 移除 theme 參數
                    
                    // 學習工具區塊
                    VStack(spacing: 8) {
                        HStack {
                            Text("學習工具")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // iLearn 作業
                        MenuCard(
                            icon: "book.fill",
                            title: "課表規劃",
                            action: { selectedTab = 1 }
                        )
                        
                        // iLearning
                        MenuCard(
                            icon: "graduationcap.fill",
                            title: "iLearning",
                            action: { 
                                // ✅ 雷點2修正：直接建立包含完整資訊的 item，確保 URL 在顯示時一定正確
                                webViewItem = WebViewItem(
                                    url: URL(string: "https://lms2020.nchu.edu.tw/")!,
                                    title: "iLearning 3.0"
                                )
                            }
                        )
                    }
                    
                    // 校園資訊區塊
                    VStack(spacing: 8) {
                        HStack {
                            Text("校園資訊")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // 興大入口
                        MenuCard(
                            icon: "globe",
                            title: "興大入口",
                            action: { 
                                webViewItem = WebViewItem(
                                    url: URL(string: "https://portal.nchu.edu.tw/")!,
                                    title: "興大入口"
                                )
                            }
                        )
                        
                        // 課程查詢系統
                        MenuCard(
                            icon: "list.clipboard",
                            title: "課程查詢系統",
                            action: { 
                                webViewItem = WebViewItem(
                                    url: URL(string: "https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home")!,
                                    title: "課程查詢系統"
                                )
                            }
                        )
                        
                        // 校園地圖
                        MenuCard(
                            icon: "map.fill",
                            title: "校園地圖",
                            action: { selectedTab = 3 }
                        )
                        
                        // 行事曆與選課時程
                        HStack(spacing: 12) {
                            MenuCard(
                                icon: "calendar",
                                title: "行事曆",
                                isHalfWidth: true,
                                action: { showingCalendar = true }
                            )
                            
                            MenuCard(
                                icon: "clock.badge.checkmark",
                                title: "選課時程",
                                isHalfWidth: true,
                                action: { 
                                    webViewItem = WebViewItem(
                                        url: URL(string: "https://onepiece.nchu.edu.tw/cofsys/plsql/vocdate_qry?v_career=U")!,
                                        title: "選課時程"
                                    )
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 個人化區塊
                    VStack(spacing: 8) {
                        HStack {
                            Text("個人化")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        MenuCard(
                            icon: "gear",
                            title: "常用功能",
                            action: { selectedTab = 4 }
                        )
                    }
                    
                    // 關於本程式區塊
                    VStack(spacing: 12) {
                        HStack {
                            Text("關於本程式")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.title)
                                .foregroundStyle(theme.accent.color)
                            
                            Text("初興")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("版本 1.0.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("Copyright © 2025 LLY")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(theme.accent.color.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
                }
                
                // AI 助手懸浮按鈕
                Button(action: {
                    showingAIAssistant = true
                }) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(theme.accent.color)
                        .clipShape(Circle())
                        .shadow(color: theme.accent.color.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding()
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            // ✅ 雷點3修正：使用 sheet(item:) 而非 sheet(isPresented:)
            // 這樣 SwiftUI 會在 item 被設定後才建立 sheet 內容，確保 URL 一定是正確的
            .sheet(item: $webViewItem) { item in
                SimpleWebViewContainer(
                    url: item.url, 
                    title: item.title,
                    useSafari: true  // 使用 SFSafariViewController（推薦）
                )
            }
            .sheet(isPresented: $showingCalendar) {
                CalendarView()
            }
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerView()
                    .environmentObject(avatarManager)
            }
            .sheet(isPresented: $showingAIAssistant) {
                AIAssistantView()
                    .environmentObject(theme)
            }
        }
    }
}

struct MenuCard: View {
    let icon: String
    let title: String
    let isHalfWidth: Bool
    let action: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    
    init(icon: String, title: String, isHalfWidth: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isHalfWidth = isHalfWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(theme.accent.color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(isHalfWidth ? 2 : 1)
                    .minimumScaleFactor(isHalfWidth ? 0.8 : 0.8)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isHalfWidth ? 0 : 20)
    }
}


// MARK: - Utilities View

struct UtilitiesView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        NavigationStack {
            List {
                Section("個人課表") {
                    NavigationLink(destination: SchedulePlannerView(scheduleVM: ScheduleVM())) {
                        Label("課表管理", systemImage: "calendar")
                    }
                    
                    NavigationLink(destination: CourseAssistantView(scheduleVM: ScheduleVM())) {
                        Label("選課小幫手", systemImage: "wand.and.stars")
                    }
                    
                    NavigationLink(destination: ScheduleExportView()) {
                        Label("課表匯出", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("校園生活") {
                    NavigationLink(destination: MedicalDiscountView()) {
                        Label("特約醫療院所", systemImage: "stethoscope")
                    }
                    
                    NavigationLink(destination: LibraryView()) {
                        Label("圖書館", systemImage: "books.vertical")
                    }
                }
                
                Section("個人設定") {
                    NavigationLink(destination: UserProfileView()) {
                        Label("個人資料", systemImage: "person.text.rectangle")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("應用設定", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("關於應用", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("常用功能")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Placeholder Views for Utilities


struct ScheduleExportView: View {
    @StateObject private var scheduleVM = ScheduleVM()  // 自動載入已儲存的課程
    @EnvironmentObject private var theme: ThemeManager
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var semester = "114-1"
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case ical = "iCal"
        
        var displayName: String {
            switch self {
            case .csv: return "CSV 格式"
            case .ical: return "iCal 格式（可匯入行事曆）"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .ical: return "ics"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .ical: return "text/calendar"
            }
        }
    }
    
    var body: some View {
        List {
            // 課程統計
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("總課程數")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(scheduleVM.courses.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.accent.color)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("總學分數")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(totalCredits)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.accent.color)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("課程資訊")
            }
            
            // 匯出格式選擇
            Section {
                Picker("匯出格式", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.displayName)
                            .tag(format)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("匯出格式")
            } footer: {
                Text(exportFormat == .csv ? "CSV 格式可用 Excel、Numbers 等軟體開啟" : "iCal 格式可直接匯入 iOS 行事曆、Google Calendar 等")
            }
            
            // 學期設定
            Section {
                TextField("學期", text: $semester)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("學期設定")
            } footer: {
                Text("用於 iCal 匯出，格式：114-1（學年度-學期）")
            }
            
            // 匯出按鈕
            Section {
                Button(action: exportSchedule) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        Text("匯出課表")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(theme.accent.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(scheduleVM.courses.isEmpty)
            }
            
            // 課程列表預覽
            if !scheduleVM.courses.isEmpty {
                Section {
                    ForEach(scheduleVM.courses.sorted(by: { $0.name < $1.name })) { course in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.name)
                                .font(.headline)
                            
                            HStack {
                                Text(course.requiredType.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.accent.color.opacity(0.2))
                                    .foregroundStyle(theme.accent.color)
                                    .clipShape(Capsule())
                                
                                Text(course.allSchedulesDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if let credits = course.credits {
                                    Text("\(credits)學分")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("課程列表")
                }
            }
        }
        .navigationTitle("課表匯出")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("匯出錯誤", isPresented: $showingError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var totalCredits: Int {
        scheduleVM.courses.compactMap { $0.credits }.reduce(0, +)
    }
    
    private func exportSchedule() {
        guard !scheduleVM.courses.isEmpty else {
            errorMessage = "沒有課程可以匯出"
            showingError = true
            return
        }
        
        let data: Data?
        let fileName: String
        
        switch exportFormat {
        case .csv:
            data = ScheduleExporter.exportToCSV(courses: scheduleVM.courses)
            fileName = "NCHU課表_\(semester).csv"
        case .ical:
            data = ScheduleExporter.exportToiCal(courses: scheduleVM.courses, semester: semester)
            fileName = "NCHU課表_\(semester).ics"
        }
        
        guard let exportData = data else {
            errorMessage = "匯出失敗：無法生成檔案"
            showingError = true
            return
        }
        
        // 將資料寫入臨時檔案
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        
        do {
            try exportData.write(to: tempURL)
            shareItems = [tempURL]
            showingShareSheet = true
        } catch {
            errorMessage = "匯出失敗：\(error.localizedDescription)"
            showingError = true
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var theme: ThemeManager
    @State private var webViewItem: WebViewItem?
    
    var body: some View {
        List {
            Section {
                // 自學空間預約系統
                Button(action: {
                    webViewItem = WebViewItem(
                        url: URL(string: "https://space.lib.nchu.edu.tw/pwaspace/")!,
                        title: "自學空間預約系統"
                    )
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundStyle(theme.accent.color)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("自學空間預約系統")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Text("預約圖書館自習空間")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                
                // 數位出入管系統
                Button(action: {
                    webViewItem = WebViewItem(
                        url: URL(string: "https://space.lib.nchu.edu.tw/pwadoor/")!,
                        title: "數位出入管系統"
                    )
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "door.left.hand.open")
                            .font(.title2)
                            .foregroundStyle(theme.accent.color)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("數位出入管系統")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Text("圖書館門禁管理")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            } header: {
                Text("常用服務")
            }
            
            Section {
                // 圖書館官網
                Button(action: {
                    webViewItem = WebViewItem(
                        url: URL(string: "https://www.lib.nchu.edu.tw/")!,
                        title: "興大圖書館"
                    )
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "building.columns")
                            .font(.title2)
                            .foregroundStyle(theme.accent.color)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("圖書館官網")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Text("查看館藏、開放時間等資訊")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            } header: {
                Text("其他連結")
            }
        }
        .navigationTitle("圖書館")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $webViewItem) { item in
            SimpleWebViewContainer(
                url: item.url,
                title: item.title,
                useSafari: true
            )
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Form {
            Section("外觀主題") {
                HStack {
                    Label("深色模式", systemImage: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $theme.isDarkMode)
                        .controlSize(.small)
                }
                
                Picker("按鈕顏色", selection: $theme.accent) {
                    ForEach(ThemeManager.AccentColor.allCases, id: \.self) { acc in
                        HStack {
                            Circle()
                                .fill(acc.color)
                                .frame(width: 16, height: 16)
                            Text(acc.displayName)
                                .foregroundStyle(.primary)
                        }
                        .tag(acc)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("課程類型顏色") {
                HStack {
                    Label("必修課程", systemImage: "book.fill")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Picker("必修顏色", selection: $theme.requiredCourseColor) {
                        ForEach(ThemeManager.CourseTypeColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.displayName)
                                    .foregroundStyle(.primary)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Label("選修課程", systemImage: "book")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Picker("選修顏色", selection: $theme.electiveCourseColor) {
                        ForEach(ThemeManager.CourseTypeColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.displayName)
                                    .foregroundStyle(.primary)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Label("通識課程", systemImage: "graduationcap")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Picker("通識顏色", selection: $theme.generalEducationColor) {
                        ForEach(ThemeManager.CourseTypeColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.displayName)
                                    .foregroundStyle(.primary)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("課程顏色預覽")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        // 必修
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.requiredCourseColor.color)
                                .frame(width: 60, height: 40)
                            Text("必修")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // 選修
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.electiveCourseColor.color)
                                .frame(width: 60, height: 40)
                            Text("選修")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // 通識
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.generalEducationColor.color)
                                .frame(width: 60, height: 40)
                            Text("通識")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            } header: {
                Text("預覽")
            }
        }
        .navigationTitle("應用設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.accent.color)
            
            Text("初興")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 1.0.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("為您精心設計的校園生活助手")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("關於應用")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - My Courses Section

struct MyCoursesSection: View {
    @ObservedObject var scheduleVM: ScheduleVM
    @Binding var selectedTab: Int
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    @StateObject private var buildingStore = BuildingStore()
    
    @State private var showingCourseDetail = false
    @State private var selectedCourse: Course?
    @State private var showingMapError = false
    @State private var mapErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 8) {
            // Section Header
            HStack {
                Text("我的課程")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !scheduleVM.courses.isEmpty {
                    Button(action: {
                        selectedTab = 1
                    }) {
                        HStack(spacing: 4) {
                            Text("查看完整課表")
                                .font(.caption)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundStyle(theme.accent.color)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Today's Courses Content
            if scheduleVM.courses.isEmpty {
                EmptyCoursesView(selectedTab: $selectedTab)  // ✅ 移除 theme 參數
            } else if scheduleVM.isTodayWeekday {
                TodayCoursesView(
                    courses: scheduleVM.getTodayCourses(),
                    scheduleVM: scheduleVM,
                    onCourseTap: { course in
                        // 如果有 buildingCode，直接開啟 Google Maps 導航
                        if !course.buildingCode.isEmpty {
                            openGoogleMapForCourse(course)
                        } else {
                            // 否則顯示課程詳情
                            selectedCourse = course
                            showingCourseDetail = true
                        }
                    }
                )  // ✅ 移除 theme 參數
            } else {
                WeekendView()  // ✅ 移除 theme 參數
            }
        }
        .task {
            await CampusUtils.loadBuildings(for: buildingStore)
        }
        .alert("導航錯誤", isPresented: $showingMapError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(mapErrorMessage)
        }
        .sheet(isPresented: $showingCourseDetail) {
            if let selectedCourse = selectedCourse {
                CourseDetailView(course: selectedCourse)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openGoogleMapForCourse(_ course: Course) {
        // 從 buildingCode 找到對應的建築物
        if let building = buildingStore.findByCode(course.buildingCode) {
            CampusUtils.openGoogleMap(for: building) { errorMessage in
                mapErrorMessage = errorMessage
                showingMapError = true
            }
        } else {
            // 如果找不到建築物，顯示錯誤訊息
            mapErrorMessage = "找不到建築物「\(course.buildingCode)」的座標資訊"
            showingMapError = true
        }
    }
}

// MARK: - Today Courses View

struct TodayCoursesView: View {
    let courses: [Course]
    @ObservedObject var scheduleVM: ScheduleVM
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    let onCourseTap: (Course) -> Void
    
    private var todayName: String {
        let weekdays = ["", "週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        return weekdays[adjustedWeekday]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if courses.isEmpty {
                NoCoursesTodayView()  // ✅ 移除 theme 參數
            } else {
                // Next Course Highlight
                if let nextCourse = scheduleVM.getNextCourseToday() {
                    NextCourseCard(course: nextCourse, onTap: onCourseTap)  // ✅ 移除 theme 參數
                } else {
                    // No more courses today
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(theme.accent.color.opacity(0.7))
                        
                        Text("今日課程已結束")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("辛苦了！明天見")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Course Row Card

struct CourseRowCard: View {
    let course: Course
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    let onTap: (Course) -> Void
    
    var body: some View {
        Button(action: { onTap(course) }) {
            HStack(spacing: 12) {
                // Time
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.periodsString + "節")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.accent.color)
                    
                    Text(timeRangeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60, alignment: .leading)
                
                // Course Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(course.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(course.requiredType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(courseTypeColor.opacity(0.2))
                            .foregroundStyle(courseTypeColor)
                            .clipShape(Capsule())
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(course.locationDescription.isEmpty ? "教室未定" : course.locationDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let instructor = course.instructor {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            
                            Text(instructor)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if course.hasSyllabus {
                            Image(systemName: "doc.text")
                                .font(.caption2)
                                .foregroundStyle(theme.accent.color.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .opacity(0.85)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
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
        // NCHU 課程時間表：
        // 第1節: 8:10-9:00, 第2節: 9:10-10:00, 第3節: 10:10-11:00, 第4節: 11:10-12:00
        // 第5節: 13:10-14:00 (下午1:10開始), 第6節: 14:10-15:00, ...
        
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
    
    private func periodToEndTimeString(_ period: Int) -> String {
        // 每節課結束時間（下一節課開始前）
        switch period {
        case 1: return "9:00"
        case 2: return "10:00"
        case 3: return "11:00"
        case 4: return "12:00"
        case 5: return "14:00"  // 第5節結束是14:00
        case 6: return "15:00"
        case 7: return "16:00"
        case 8: return "17:00"
        case 9: return "18:00"
        case 10: return "19:00"
        case 11: return "20:00"
        case 12: return "21:00"
        case 13: return "22:00"
        case 14: return "23:00"
        default: return "時間未定"
        }
    }
    
    private var courseTypeColor: Color {
        return NCHUColors.courseTypeColor(for: course.requiredType, theme: theme)
    }
}

// MARK: - Next Course Card

struct NextCourseCard: View {
    let course: Course
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    @StateObject private var buildingStore = BuildingStore()
    let onTap: (Course) -> Void
    
    @State private var showingMapError = false
    @State private var mapErrorMessage = ""
    
    var body: some View {
        Button(action: { onTap(course) }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("下一堂課")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.accent.color)
                    
                    Spacer()
                    
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(theme.accent.color.opacity(0.7))
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(course.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text("\(course.periodsString)節")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button(course.locationDescription.isEmpty ? "教室未定" : course.locationDescription) {
                                if !course.buildingCode.isEmpty {
                                    openGoogleMapForBuilding(course.buildingCode)
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(!course.buildingCode.isEmpty ? theme.accent.color : .secondary)
                            .buttonStyle(.plain)
                            .disabled(course.buildingCode.isEmpty)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(theme.accent.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .task {
            await CampusUtils.loadBuildings(for: buildingStore)
        }
        .alert("導航錯誤", isPresented: $showingMapError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(mapErrorMessage)
        }
    }
    
    private func openGoogleMapForBuilding(_ buildingCode: String) {
        if let building = buildingStore.findByCode(buildingCode) {
            CampusUtils.openGoogleMap(for: building) { errorMessage in
                mapErrorMessage = errorMessage
                showingMapError = true
            }
        } else {
            mapErrorMessage = "找不到建築物「\(buildingCode)」的座標資訊"
            showingMapError = true
        }
    }
}

// MARK: - Helper Views

struct EmptyCoursesView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.title)
                .foregroundStyle(theme.accent.color.opacity(0.7))
            
            Text("還沒有課程")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("開始建立您的課表吧！")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button(action: {
                selectedTab = 1
            }) {
                Text("建立課表")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.accent.color)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct NoCoursesTodayView: View {
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cup.and.saucer")
                .font(.title2)
                .foregroundStyle(theme.accent.color.opacity(0.7))
            
            Text("今天沒有課程")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("好好享受空閒時光吧！")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct WeekendView: View {
    @EnvironmentObject private var theme: ThemeManager  // ✅ 改用 @EnvironmentObject 確保顏色更新
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars")
                .font(.title2)
                .foregroundStyle(theme.accent.color.opacity(0.7))
            
            Text("週末愉快")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("好好休息，準備下週的課程吧！")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}


// MARK: - WebView Item for Sheet Presentation
// ✅ 用於解決雷點2和雷點3：確保 sheet 顯示時 URL 和 title 一定是正確的值
struct WebViewItem: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

#Preview {
    MainTabView()
        .environmentObject(ThemeManager())
}
