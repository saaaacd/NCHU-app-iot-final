//
//  NCHUHelperApp.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import SwiftUI
import WebKit

@main
struct NCHUHelperApp: App {
    @StateObject private var theme = ThemeManager()
    
    init() {
        // App 啟動時預初始化 WebView，解決首次載入白畫面問題
        preWarmWebView()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(theme)
                .preferredColorScheme(theme.isDarkMode ? .dark : .light)
                .tint(theme.accent.color)
                .onAppear {
                    // 確保CourseDataStore開始加載數據
                    print("📚 App啟動：開始預加載課程數據")
                    let _ = CourseDataStore.shared // 立即觸發單例初始化
                    print("📚 CourseDataStore.shared initialized")
                }
        }
    }
    
    // 預熱 WebView 以解決首次載入問題
    private func preWarmWebView() {
        print("🌐 開始預熱 WebView...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let config = WKWebViewConfiguration()
            config.websiteDataStore = WKWebsiteDataStore.default()
            
            let preWarmWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
            
            // 載入興大首頁觸發網絡權限和 SSL 憑證預載
            if let url = URL(string: "https://www.nchu.edu.tw") {
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
                preWarmWebView.load(request)
                print("🌐 WebView 預熱請求已發送：興大官網")
            }
            
            // 2秒後釋放預熱 WebView
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🌐 WebView 預熱完成")
                _ = preWarmWebView // 確保引用在這裡才被釋放
            }
        }
    }
}
