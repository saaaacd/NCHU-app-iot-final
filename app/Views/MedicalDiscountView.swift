import SwiftUI

struct MedicalDiscountView: View {
    @StateObject private var discountStore = MedicalDiscountStore()
    @EnvironmentObject private var theme: ThemeManager
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var showingDiscountDetail = false
    @State private var selectedDiscount: MedicalDiscount?
    @State private var showingMapView = false
    
    private var filteredDiscounts: [MedicalDiscount] {
        var discounts = discountStore.allDiscounts
        
        // 搜尋篩選
        if !searchText.isEmpty {
            let lowercaseKeyword = searchText.lowercased()
            discounts = discounts.filter { discount in
                discount.hospitalName.lowercased().contains(lowercaseKeyword) ||
                discount.category.lowercased().contains(lowercaseKeyword) ||
                discount.specialtyMedicine.lowercased().contains(lowercaseKeyword) ||
                discount.address.lowercased().contains(lowercaseKeyword)
            }
        }
        
        // 分類篩選
        if selectedCategory != "全部" {
            discounts = discounts.filter { $0.category == selectedCategory }
        }
        
        // 按優先順序排序
        let priorityOrder = ["耳鼻喉科", "中醫", "眼科", "牙科", "綜合醫院"]
        
        return discounts.sorted { discount1, discount2 in
            let index1 = priorityOrder.firstIndex(of: discount1.category) ?? priorityOrder.count
            let index2 = priorityOrder.firstIndex(of: discount2.category) ?? priorityOrder.count
            
            if index1 != index2 {
                return index1 < index2
            }
            
            // 如果是同一類別，按醫院名稱排序
            return discount1.hospitalName < discount2.hospitalName
        }
    }
    
    private var categories: [String] {
        ["全部"] + discountStore.availableCategories
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 搜尋欄
                    searchSection
                        .padding(.bottom, 20)
                    
                    // 分類篩選
                    categoryFilterSection
                        .padding(.bottom, searchText.isEmpty && selectedCategory == "全部" ? 20 : 10)
                    
                    // 特色推薦
                    if searchText.isEmpty && selectedCategory == "全部" {
                        featuredSection
                            .padding(.bottom, 10)
                    }
                    
                    // 醫院診所列表
                    discountListSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .navigationTitle("特約醫療院所")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingMapView = true
                    }) {
                        Image(systemName: "map")
                            .font(.title2)
                            .foregroundStyle(theme.accent.color)
                    }
                }
            }
            .refreshable {
                discountStore.loadDiscounts()
            }
        }
        .sheet(item: $selectedDiscount) { discount in
            MedicalDiscountDetailView(discount: discount)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showingMapView) {
            MedicalDiscountMapView(discounts: filteredDiscounts)
                .environmentObject(theme)
        }
        .onAppear {
            if discountStore.allDiscounts.isEmpty {
                discountStore.loadDiscounts()
            }
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("搜尋醫院、診所或科別...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    MedicalFilterButton(
                        title: category,
                        isSelected: selectedCategory == category,
                        icon: getIconForCategory(category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("重點推薦")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 優先顯示耳鼻喉科和中醫
                    ForEach(discountStore.allDiscounts.filter { $0.category == "耳鼻喉科" || $0.category == "中醫" }.prefix(4), id: \.id) { discount in
                        FeaturedDiscountCard(discount: discount) {
                            selectedDiscount = discount
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var discountListSection: some View {
        LazyVStack(spacing: 12) {
            if discountStore.isLoading {
                ForEach(0..<5, id: \.self) { _ in
                    DiscountCardSkeleton()
                }
            } else if filteredDiscounts.isEmpty {
                EmptyStateView(
                    title: searchText.isEmpty ? "暫無資料" : "找不到相關醫院診所",
                    subtitle: searchText.isEmpty ? "請稍後再試" : "試試其他關鍵字或分類",
                    icon: "stethoscope"
                )
            } else {
                ForEach(filteredDiscounts, id: \.id) { discount in
                    DiscountCard(discount: discount) {
                        selectedDiscount = discount
                    }
                }
            }
        }
    }
    
    
    private func getIconForCategory(_ category: String) -> String {
        switch category {
        case "全部": return "list.bullet"
        case "綜合醫院": return "building.2"
        case "外科": return "staroflife"
        case "牙科": return "mouth"
        case "中醫": return "leaf"
        case "眼科": return "eye"
        case "皮膚科": return "hand.raised"
        case "家醫科": return "person.fill.badge.plus"
        case "耳鼻喉科": return "ear"
        case "內科", "胸腔內科": return "lungs"
        case "身心科": return "brain.head.profile"
        case "骨科", "骨科/聯合": return "figure.walk"
        default: return "cross.case"
        }
    }
}

// MARK: - Supporting Views

struct MedicalFilterButton: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? theme.accent.color : Color(.systemBackground)
            )
            .foregroundStyle(
                isSelected ? .white : .primary
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeaturedDiscountCard: View {
    let discount: MedicalDiscount
    let action: () -> Void
    
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: discount.categoryIcon)
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(discount.discountLevel.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(discount.discountLevel.color).opacity(0.2))
                        .foregroundStyle(Color(discount.discountLevel.color))
                        .clipShape(Capsule())
                }
                
                Text(discount.hospitalName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(discount.shortDiscountDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(width: 200, height: 120)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscountCard: View {
    let discount: MedicalDiscount
    let action: () -> Void
    
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 圖標
                ZStack {
                    Circle()
                        .fill(theme.accent.color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: discount.categoryIcon)
                        .font(.title2)
                        .foregroundStyle(theme.accent.color)
                }
                
                // 內容
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(discount.hospitalName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(discount.discountLevel.text)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(discount.discountLevel.color).opacity(0.2))
                            .foregroundStyle(Color(discount.discountLevel.color))
                            .clipShape(Capsule())
                    }
                    
                    Text(discount.shortDiscountDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(discount.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: discount.googleMapsURL) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                Text("導航")
                            }
                            .font(.caption)
                            .foregroundStyle(theme.accent.color)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscountCardSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmer()
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmer()
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 10)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmer()
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Extensions

extension View {
    func shimmer() -> some View {
        self.redacted(reason: .placeholder)
    }
}

// MARK: - Preview

#Preview {
    MedicalDiscountView()
        .environmentObject(ThemeManager())
}
