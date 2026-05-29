//
//  UserProfileView.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/9/25.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var profileManager = UserProfileManager.shared
    
    @State private var editedName: String = ""
    @State private var editedDepartment: String = ""
    @State private var editedGrade: String = ""
    @State private var showingGradePicker = false
    @State private var showingDepartmentPicker = false
    
    // 可選的年級
    private let grades = ["一年級", "二年級", "三年級", "四年級", "五年級", "研一", "研二", "研三", "博一", "博二", "博三", "博四"]
    
    // 常見系所列表
    private let commonDepartments = [
        "資訊工程學系",
        "電機工程學系A班",
        "電機工程學系B班",
        "電機資訊學院",
        "機械工程學系",
        "土木工程學系",
        "化學工程學系",
        "材料科學與工程學系",
        "環境工程學系",
        "精密工程學系",
        "生物醫學工程學系",
        "企業管理學系",
        "財務金融學系",
        "資訊管理學系",
        "國際經營與貿易學系",
        "會計學系",
        "應用經濟學系",
        "行銷學系",
        "中國文學系",
        "外國語文學系",
        "歷史學系",
        "應用數學系",
        "物理學系",
        "化學系",
        "生命科學系",
        "食品暨應用生物科技學系",
        "獸醫學系",
        "動物科學系",
        "森林學系",
        "園藝學系",
        "植物病理學系",
        "昆蟲學系",
        "土壤環境科學系",
        "生物科技學研究所",
        "景觀與遊憩學士學位學程"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本資料")) {
                    // 姓名
                    HStack {
                        Text("姓名")
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        TextField("請輸入姓名", text: $editedName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(editedName.isEmpty ? .secondary : .primary)
                    }
                    
                    // 系所
                    HStack {
                        Text("系所")
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingDepartmentPicker = true
                        }) {
                            Text(editedDepartment.isEmpty ? "選擇系所" : editedDepartment)
                                .foregroundStyle(editedDepartment.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 年級
                    HStack {
                        Text("年級")
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingGradePicker = true
                        }) {
                            Text(editedGrade.isEmpty ? "選擇年級" : editedGrade)
                                .foregroundStyle(editedGrade.isEmpty ? .secondary : .primary)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                }
                
                Section(header: Text("預覽")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(editedName.isEmpty ? "姓名" : "\(editedName.prefix(1))同學")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(editedName.isEmpty ? .secondary : .primary)
                            
                            HStack {
                                // 顯示系所名稱
                                if !editedDepartment.isEmpty {
                                    Text(editedDepartment)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if !editedDepartment.isEmpty && !editedGrade.isEmpty {
                                    Text("・")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if !editedGrade.isEmpty {
                                    Text(editedGrade)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                            .foregroundStyle(theme.accent.color.opacity(0.7))
                    }
                    .padding(.vertical, 8)
                }
                
            }
            .navigationTitle("個人資料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadProfileData()
            }
            .sheet(isPresented: $showingGradePicker) {
                NavigationStack {
                    List {
                        ForEach(grades, id: \.self) { grade in
                            Button(action: {
                                editedGrade = grade
                                showingGradePicker = false
                            }) {
                                HStack {
                                    Text(grade)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if editedGrade == grade {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(theme.accent.color)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("選擇年級")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                showingGradePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingDepartmentPicker) {
                NavigationStack {
                    VStack(spacing: 0) {
                        // 自訂輸入區域
                        VStack(spacing: 12) {
                            HStack {
                                Text("自訂系所")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            TextField("輸入您的系所名稱", text: $editedDepartment)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    showingDepartmentPicker = false
                                }
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        
                        Divider()
                        
                        // 常見系所列表
                        List {
                            Section("常見系所") {
                                ForEach(commonDepartments, id: \.self) { department in
                                    Button(action: {
                                        editedDepartment = department
                                        showingDepartmentPicker = false
                                    }) {
                                        HStack {
                                            Text(department)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            if editedDepartment == department {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(theme.accent.color)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("選擇系所")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                showingDepartmentPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.large])
            }
        }
    }
    
    private func loadProfileData() {
        editedName = profileManager.profile.name
        editedDepartment = profileManager.profile.department
        editedGrade = profileManager.profile.grade
    }
    
    private func saveProfile() {
        profileManager.profile = UserProfile(
            name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
            department: editedDepartment.trimmingCharacters(in: .whitespacesAndNewlines),
            grade: editedGrade.trimmingCharacters(in: .whitespacesAndNewlines),
            classGroup: nil
        )
    }
}
