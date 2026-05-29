//
//  AvatarManager.swift
//  Campus
//

import SwiftUI
import Combine
import PhotosUI

// MARK: - Avatar Types
enum AvatarStyle: String, CaseIterable, Identifiable {
    case duckStudent = "duck_student"
    case duckCoffee = "duck_coffee"
    case duckTech = "duck_tech"
    case duckChef = "duck_chef"
    case duckProgrammer = "duck_programmer"
    case duckTraveler = "duck_traveler"
    case duckGraduate = "duck_graduate"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .duckStudent:
            return "熬夜鴨"
        case .duckCoffee:
            return "咖啡鴨"
        case .duckTech:
            return "化學鴨"
        case .duckChef:
            return "廚師鴨"
        case .duckProgrammer:
            return "程式鴨"
        case .duckTraveler:
            return "旅行鴨"
        case .duckGraduate:
            return "畢業鴨"
        case .custom:
            return "自定義照片"
        }
    }
    
    var imageName: String? {
        switch self {
        case .duckStudent:
            return "duck_student"
        case .duckCoffee:
            return "duck_coffee"
        case .duckTech:
            return "duck_tech"
        case .duckChef:
            return "duck_chef"
        case .duckProgrammer:
            return "duck_programmer"
        case .duckTraveler:
            return "duck_traveler"
        case .duckGraduate:
            return "duck_graduate"
        case .custom:
            return nil
        }
    }
    
    var backgroundColor: Color {
        // 統一使用純白色背景
        return .white
    }
}

// MARK: - Avatar Manager
@MainActor
final class AvatarManager: ObservableObject {
    @Published var selectedAvatar: AvatarStyle = .duckStudent
    @Published var customAvatarImage: UIImage?
    
    private let userDefaults = UserDefaults.standard
    private let avatarKey = "selectedAvatar"
    private let customImageKey = "customAvatarImage"
    
    init() {
        loadSelectedAvatar()
        loadCustomImage()
    }
    
    func selectAvatar(_ avatar: AvatarStyle) {
        selectedAvatar = avatar
        saveSelectedAvatar()
    }
    
    func setCustomImage(_ image: UIImage) {
        customAvatarImage = image
        selectedAvatar = .custom
        saveCustomImage()
        saveSelectedAvatar()
    }
    
    private func loadSelectedAvatar() {
        if let savedAvatarRawValue = userDefaults.string(forKey: avatarKey),
           let savedAvatar = AvatarStyle(rawValue: savedAvatarRawValue) {
            selectedAvatar = savedAvatar
        }
    }
    
    private func saveSelectedAvatar() {
        userDefaults.set(selectedAvatar.rawValue, forKey: avatarKey)
    }
    
    private func loadCustomImage() {
        if let imageData = userDefaults.data(forKey: customImageKey),
           let image = UIImage(data: imageData) {
            customAvatarImage = image
        }
    }
    
    private func saveCustomImage() {
        if let image = customAvatarImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            userDefaults.set(imageData, forKey: customImageKey)
        }
    }
}

// MARK: - Avatar View Component
struct AvatarView: View {
    let avatar: AvatarStyle
    let customImage: UIImage?
    let size: CGFloat
    
    init(_ avatar: AvatarStyle, customImage: UIImage? = nil, size: CGFloat = 80) {
        self.avatar = avatar
        self.customImage = customImage
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(avatar.backgroundColor)
                .frame(width: size, height: size)
            
            if avatar == .custom, let customImage = customImage {
                Image(uiImage: customImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let imageName = avatar.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.85, height: size * 0.85)
            } else if avatar == .custom {
                // 占位符當沒有自定義圖片時
                Image(systemName: "photo.circle.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.gray)
            }
        }
    }
}

// MARK: - Avatar Picker View
struct AvatarPickerView: View {
    @EnvironmentObject var avatarManager: AvatarManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(AvatarStyle.allCases) { avatar in
                                VStack(spacing: 6) {
                                    if avatar == .custom {
                                        // 自定義照片選擇按鈕
                                        Button(action: {
                                            showingPhotoPicker = true
                                        }) {
                                            AvatarView(avatar, customImage: avatarManager.customAvatarImage, size: 65)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            avatarManager.selectedAvatar == avatar ? .blue : .clear,
                                                            lineWidth: 2.5
                                                        )
                                                )
                                                .scaleEffect(avatarManager.selectedAvatar == avatar ? 1.05 : 1.0)
                                                .overlay(
                                                    // 添加編輯圖標
                                                    Image(systemName: "pencil.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.blue)
                                                        .background(.white)
                                                        .clipShape(Circle())
                                                        .offset(x: 22, y: -22)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        // 預設頭像選擇按鈕
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                avatarManager.selectAvatar(avatar)
                                            }
                                        }) {
                                            AvatarView(avatar, customImage: avatarManager.customAvatarImage, size: 65)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            avatarManager.selectedAvatar == avatar ? .blue : .clear,
                                                            lineWidth: 2.5
                                                        )
                                                )
                                                .scaleEffect(avatarManager.selectedAvatar == avatar ? 1.05 : 1.0)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Text(avatar.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("選擇頭像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let newValue,
                       let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                avatarManager.setCustomImage(image)
                            }
                        }
                    }
                    selectedPhotoItem = nil
                }
            }
        }
    }
}

#if DEBUG
struct AvatarPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarPickerView()
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(AvatarStyle.allCases) { avatar in
                HStack {
                    AvatarView(avatar, customImage: nil, size: 60)
                    Text(avatar.displayName)
                    Spacer()
                }
            }
        }
        .padding()
    }
}
#endif
