//
//  WebViewConfig.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2024/12/19.
//

import WebKit
import Foundation

/// WebView 設定工廠，提供共享配置和進程池
final class WebViewConfigFactory {
    
    // MARK: - Shared Resources
    
    /// 共享進程池，確保多個 WebView 間 session 共享
    /// 注意：iOS 15+ 中系統自動管理進程池，無需手動設定
    @available(iOS, deprecated: 15.0, message: "WKProcessPool sharing is automatically handled by the system in iOS 15+")
    static let sharedProcessPool = WKProcessPool()
    
    /// 共享網站資料存儲
    static let sharedDataStore = WKWebsiteDataStore.default()
    
    // MARK: - Configuration Factory
    
    /// 建立 WebView 配置
    /// - Parameters:
    ///   - customUserAgent: 自定義 User Agent，用於相容舊站
    ///   - enableJSBridge: 是否啟用 JS 橋接
    /// - Returns: 配置好的 WKWebViewConfiguration
    static func createConfiguration(
        customUserAgent: String? = nil,
        enableJSBridge: Bool = true
    ) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        
        // 使用共享進程池（iOS 15+ 已無效果但向後兼容）
        if #available(iOS 15.0, *) {
            // iOS 15+ 系統自動管理進程池
        } else {
            config.processPool = sharedProcessPool
        }
        config.websiteDataStore = sharedDataStore
        
        // 媒體播放設定
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // JavaScript 設定（使用現代 API）
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // iOS 14+ 設定
        if #available(iOS 14.0, *) {
            config.limitsNavigationsToAppBoundDomains = false
        }
        
        // 自定義 User Agent
        if let userAgent = customUserAgent {
            config.applicationNameForUserAgent = userAgent
        }
        
        // JS 橋接設定
        if enableJSBridge {
            let contentController = WKUserContentController()
            // JS 橋接將在 WebView 創建時動態設置
            config.userContentController = contentController
        }
        
        return config
    }
    
    /// 預設配置
    static var defaultConfiguration: WKWebViewConfiguration {
        return createConfiguration()
    }
    
    /// 校園系統專用配置（可能需要特殊 User Agent）
    static var campusConfiguration: WKWebViewConfiguration {
        return createConfiguration(
            customUserAgent: "NCHUHelper/1.0 (iOS)",
            enableJSBridge: true
        )
    }
}

// MARK: - WebView Pool Manager

/// WebView 實例池管理器，避免重複建立造成白屏
final class WebViewPool {
    static let shared = WebViewPool()
    
    private var pool: [String: WKWebView] = [:]
    private let queue = DispatchQueue(label: "webview.pool", qos: .userInitiated)
    
    private init() {}
    
    /// 獲取或建立 WebView 實例
    func getWebView(for identifier: String, config: WKWebViewConfiguration) -> WKWebView {
        return queue.sync {
            if let existingWebView = pool[identifier] {
                return existingWebView
            }
            
            let webView = WKWebView(frame: .zero, configuration: config)
            pool[identifier] = webView
            return webView
        }
    }
    
    /// 清理指定 WebView
    func removeWebView(for identifier: String) {
        queue.sync {
            _ = pool.removeValue(forKey: identifier)
        }
    }
    
    /// 清理所有 WebView
    func clearAll() {
        queue.sync {
            pool.removeAll()
        }
    }
}
