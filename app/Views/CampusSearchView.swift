//
//  CampusSearchView.swift
//  初興 (NCHUHelper)
//
//  Created by 劉李陽 on 2025/9/21.
//

import SwiftUI
import UIKit

struct CampusSearchView: View {
    @StateObject private var buildingStore = BuildingStore()
    @EnvironmentObject private var theme: ThemeManager
    @State private var searchText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingMap = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Section
                searchSection
                
                // Content Section
                if buildingStore.isLoading {
                    loadingView
                } else if buildingStore.isEmpty {
                    emptyStateView
                } else {
                    buildingListSection
                }
            }
            .navigationTitle("校園地圖")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadBuildings()
            }
            .alert("錯誤", isPresented: $showingError) {
                Button("確定") { }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showingMap) {
                CampusMapView()
            }
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            // Search Bar with Map Button
            HStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("搜尋建築物代號、名稱或別名", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .opacity(0.8)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                
                // Map Button
                Button(action: { showingMap = true }) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(theme.accent.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Search Stats
            if !buildingStore.isEmpty {
                HStack {
                    Text("共 \(filteredBuildings.count) 個建築物")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !searchText.isEmpty {
                        Text("搜尋結果：\(filteredBuildings.count) 項")
                            .font(.caption)
                            .foregroundStyle(theme.accent.color)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.85)
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
            
            Text("載入建築資料中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundStyle(theme.accent.color)
            
            VStack(spacing: 8) {
                Text("無建築資料")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("建築資料載入失敗，請稍後再試")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { Task { await loadBuildings() } }) {
                Text("重新載入")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Building List Section
    
    private var buildingListSection: some View {
        List(filteredBuildings) { building in
            BuildingRowView(
                building: building,
                onGoogleMapTap: { openGoogleMap(building: building) }
            )
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Computed Properties
    
    private var filteredBuildings: [Building] {
        buildingStore.search(matching: searchText)
    }
    
    // MARK: - Actions
    
    private func loadBuildings() async {
        await CampusUtils.loadBuildings(for: buildingStore)
        
        // Only show error if we completely failed to load any data
        if let error = buildingStore.errorMessage, buildingStore.all.isEmpty {
            errorMessage = error
            showingError = true
        }
        
        // Debug: Print loading status
        print("📍 Buildings loaded: \(buildingStore.all.count) items")
    }
    
    private func openGoogleMap(building: Building) {
        CampusUtils.openGoogleMap(for: building) { errorMessage in
            showError(errorMessage)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Building Row View

struct BuildingRowView: View {
    let building: Building
    let onGoogleMapTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Building Info
            VStack(alignment: .leading, spacing: 6) {
                // Name and Code
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(building.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("大樓代號：\(building.code)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Open Hours
                if let openHours = building.openHours {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(openHours)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Navigation Button
            HStack {
                Spacer()
                Button(action: onGoogleMapTap) {
                    HStack(spacing: 3) {
                        Image(systemName: "globe")
                            .font(.caption)
                        Text("Google 地圖")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        CampusSearchView()
    }
}

#Preview("Building Row") {
    List {
        BuildingRowView(
            building: Building.sampleBuildings[0],
            onGoogleMapTap: { print("Google Map tapped") }
        )
        
        BuildingRowView(
            building: Building.sampleBuildings[1],
            onGoogleMapTap: { print("Google Map tapped") }
        )
    }
    .listStyle(.insetGrouped)
}