import SwiftUI

struct MedicalDiscountDetailView: View {
    let discount: MedicalDiscount
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @State private var showingCallSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 醫院基本信息
                    hospitalHeaderSection
                    
                    // 優惠信息
                    discountInfoSection
                    
                    // 特色醫療
                    specialtySection
                    
                    // 聯絡資訊
                    contactSection
                    
                    // 操作按鈕
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("醫院詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("撥打電話", isPresented: $showingCallSheet) {
            Button("撥打 \(discount.phone)") {
                if let url = URL(string: "tel://\(discount.phone)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("確定要撥打電話給 \(discount.hospitalName) 嗎？")
        }
    }
    
    private var hospitalHeaderSection: some View {
        VStack(spacing: 16) {
            // 醫院圖標和名稱
            HStack {
                ZStack {
                    Circle()
                        .fill(theme.accent.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: discount.categoryIcon)
                        .font(.largeTitle)
                        .foregroundStyle(theme.accent.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(discount.hospitalName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(discount.category)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                        
                        Text(discount.discountLevel.text)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(discount.discountLevel.color).opacity(0.2))
                            .foregroundStyle(Color(discount.discountLevel.color))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var discountInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "percent")
                    .foregroundStyle(theme.accent.color)
                Text("優惠內容")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // 適用對象
                HStack(alignment: .top) {
                    Image(systemName: "person.2")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("適用對象")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(discount.eligiblePersons)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // 優惠項目
                HStack(alignment: .top) {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("優惠項目")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(parseDiscountItems(), id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(theme.accent.color)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)
                                    
                                    Text(item)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var specialtySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundStyle(theme.accent.color)
                Text("特色醫療")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(discount.specialtyMedicine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(theme.accent.color)
                Text("聯絡資訊")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // 地址
                HStack(alignment: .top) {
                    Image(systemName: "location")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("地址")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(discount.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // 電話
                HStack {
                    Image(systemName: "phone")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("電話")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(discount.phone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 地圖導航按鈕
            Button(action: {
                if let url = URL(string: discount.googleMapsURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "map")
                        .font(.headline)
                    Text("開啟地圖導航")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.accent.color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
            
            // 撥打電話按鈕
            Button(action: {
                showingCallSheet = true
            }) {
                HStack {
                    Image(systemName: "phone")
                        .font(.headline)
                    Text("撥打電話")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(theme.accent.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.accent.color, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func parseDiscountItems() -> [String] {
        let items = discount.discountItems.components(separatedBy: "\n")
        return items.compactMap { item in
            let cleanItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanItem.isEmpty { return nil }
            
            // 移除數字編號
            let patterns = ["^\\d+\\.\\s*", "^[\\d]+\\)\\s*", "^[•·]\\s*"]
            var result = cleanItem
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(result.startIndex..., in: result)
                    result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
                }
            }
            
            return result.isEmpty ? cleanItem : result
        }
    }
}

#Preview {
    MedicalDiscountDetailView(
        discount: MedicalDiscount.sampleDiscounts[0]
    )
    .environmentObject(ThemeManager())
}
