import SwiftUI
import MapKit

struct MedicalDiscountMapView: View {
    let discounts: [MedicalDiscount]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @State private var selectedDiscount: MedicalDiscount?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map {
                    UserAnnotation()
                    
                    ForEach(discounts, id: \.id) { discount in
                        Annotation(discount.hospitalName, coordinate: discount.coordinate) {
                            Button(action: {
                                selectedDiscount = discount
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(theme.accent.color)
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: discount.categoryIcon)
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Text(discount.hospitalName)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                                        .lineLimit(1)
                                }
                            }
                            .scaleEffect(selectedDiscount?.id == discount.id ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedDiscount?.id)
                        }
                    }
                }
                .mapControlVisibility(.automatic)
                .ignoresSafeArea(.all, edges: .all)
                
                // 底部資訊卡片
                if let selectedDiscount = selectedDiscount {
                    VStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(selectedDiscount.hospitalName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("關閉") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        self.selectedDiscount = nil
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            
                            Text(selectedDiscount.shortDiscountDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            
                            HStack {
                                Text(selectedDiscount.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                                
                                Text(selectedDiscount.discountLevel.text)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(selectedDiscount.discountLevel.color).opacity(0.2))
                                    .foregroundStyle(Color(selectedDiscount.discountLevel.color))
                                    .clipShape(Capsule())
                                
                                Spacer()
                                
                                Button(action: {
                                    if let url = URL(string: selectedDiscount.googleMapsURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location")
                                        Text("導航")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(theme.accent.color)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedDiscount)
                }
            }
            .navigationTitle("特約醫療地圖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MedicalDiscountMapView(discounts: [])
        .environmentObject(ThemeManager())
}
