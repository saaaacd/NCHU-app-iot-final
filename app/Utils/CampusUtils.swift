//
//  CampusUtils.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/9/29.
//  整合重複的校園功能程式碼
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Campus Utilities
enum CampusUtils {
    
    // MARK: - Google Maps Integration
    static func openGoogleMap(for building: Building, onError: @escaping (String) -> Void = { _ in }) {
        #if canImport(UIKit)
        // Try Google Maps app first
        if let appURL = building.googleMapURL(),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        
        // Fallback to web version
        guard let webURL = building.googleMapWebURL() else {
            onError("無法開啟 Google 地圖")
            return
        }
        
        UIApplication.shared.open(webURL) { success in
            if !success {
                onError("無法開啟 Google 地圖")
            }
        }
        #elseif canImport(AppKit)
        // For macOS, use web version directly
        guard let webURL = building.googleMapWebURL() else {
            onError("無法開啟 Google 地圖")
            return
        }
        
        NSWorkspace.shared.open(webURL)
        #endif
    }
    
    // MARK: - Building Data Loading
    static func loadBuildings(for store: BuildingStore) async {
        store.load()
        
        // Wait for loading to complete
        while store.isLoading {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        if store.errorMessage != nil {
            print("⚠️ 載入建築物資料時發生錯誤")
        }
    }
}

