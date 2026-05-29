//
//  UserProfile.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/9/25.
//

import Foundation
import Combine

struct UserProfile: Codable {
    var name: String
    var department: String
    var grade: String
    var classGroup: String? // 保留兼容性，但不再使用
    
    static let `default` = UserProfile(
        name: "請設定姓名",
        department: "請選擇系所",
        grade: "請選擇年級",
        classGroup: nil
    )
}

/// 管理用戶個人資料的單例類
@MainActor
final class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var profile: UserProfile {
        didSet {
            saveProfile()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "UserProfile"
    
    private init() {
        // 從 UserDefaults 載入個人資料
        if let data = userDefaults.data(forKey: profileKey),
           let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decodedProfile
        } else {
            // 使用預設資料
            self.profile = UserProfile.default
            saveProfile()
        }
    }
    
    private func saveProfile() {
        if let encodedData = try? JSONEncoder().encode(profile) {
            userDefaults.set(encodedData, forKey: profileKey)
        }
    }
    
}
