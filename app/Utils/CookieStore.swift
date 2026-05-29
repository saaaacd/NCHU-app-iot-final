//
//  CookieStore.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2024/12/19.
//

import WebKit
import Foundation

/// Cookie 管理器，處理登入狀態保持
final class CookieStore {
    
    static let shared = CookieStore()
    private let httpCookieStore: WKHTTPCookieStore
    
    private init() {
        self.httpCookieStore = WebViewConfigFactory.sharedDataStore.httpCookieStore
    }
    
    // MARK: - Cookie Management
    
    /// 設定 Cookies 到指定域名
    /// - Parameters:
    ///   - cookies: 要設定的 Cookie 陣列
    ///   - domain: 目標域名
    @MainActor
    func setCookies(_ cookies: [HTTPCookie], for domain: URL) async throws {
        for cookie in cookies {
            await httpCookieStore.setCookie(cookie)
            print("✅ Cookie 設定成功: \(cookie.name) for \(cookie.domain)")
        }
    }
    
    /// 獲取所有 Cookies
    @MainActor
    func getAllCookies() async -> [HTTPCookie] {
        return await httpCookieStore.allCookies()
    }
    
    /// 獲取指定域名的 Cookies
    @MainActor
    func getCookies(for domain: String) async -> [HTTPCookie] {
        let allCookies = await getAllCookies()
        return allCookies.filter { cookie in
            cookie.domain.contains(domain) || domain.contains(cookie.domain)
        }
    }
    
    /// 刪除指定域名的 Cookies
    @MainActor
    func deleteCookies(for domain: String) async {
        let cookiesToDelete = await getCookies(for: domain)
        for cookie in cookiesToDelete {
            await httpCookieStore.deleteCookie(cookie)
            print("🗑️ 已刪除 Cookie: \(cookie.name) for \(cookie.domain)")
        }
    }
    
    /// 清除所有 Cookies
    @MainActor
    func clearAllCookies() async {
        let allCookies = await getAllCookies()
        for cookie in allCookies {
            await httpCookieStore.deleteCookie(cookie)
        }
        print("🗑️ 已清除所有 Cookies")
    }
    
    // MARK: - SSO Integration
    
    /// 從 UserDefaults 載入並注入 SSO Cookies
    @MainActor
    func loadSSOCookies(for domain: URL) async throws {
        guard let cookieData = UserDefaults.standard.data(forKey: "sso_cookies_\(domain.host ?? "")"),
              let cookies = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: cookieData) as? [HTTPCookie] else {
            print("⚠️ 未找到 SSO Cookies for \(domain.host ?? "")")
            return
        }
        
        try await setCookies(cookies, for: domain)
        print("✅ SSO Cookies 載入完成")
    }
    
    /// 儲存 SSO Cookies 到 UserDefaults
    @MainActor
    func saveSSOCookies(for domain: URL) async throws {
        let cookies = await getCookies(for: domain.host ?? "")
        
        guard !cookies.isEmpty else {
            print("⚠️ 沒有 Cookies 需要儲存")
            return
        }
        
        let cookieData = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: true)
        UserDefaults.standard.set(cookieData, forKey: "sso_cookies_\(domain.host ?? "")")
        print("✅ SSO Cookies 儲存完成")
    }
}

// MARK: - Errors

enum CookieError: LocalizedError {
    case setCookieFailed(String, Error)
    case loadFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .setCookieFailed(let name, let error):
            return "設定 Cookie '\(name)' 失敗: \(error.localizedDescription)"
        case .loadFailed(let domain):
            return "載入 '\(domain)' 的 Cookies 失敗"
        case .saveFailed(let domain):
            return "儲存 '\(domain)' 的 Cookies 失敗"
        }
    }
}

// MARK: - Sample Cookies for Testing

extension CookieStore {
    
    /// 建立測試用的登入 Cookie
    static func createSampleLoginCookie(for domain: String) -> HTTPCookie? {
        return HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: "session_token",
            .value: "sample_token_12345",
            .secure: "TRUE",
            .expires: Date().addingTimeInterval(86400 * 7) // 7 天後過期
        ])
    }
    
    /// 建立範例 SSO Cookies
    static func createSampleSSOCookies(for domain: String) -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []
        
        // 登入狀態 Cookie
        if let loginCookie = HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: "JSESSIONID",
            .value: "ABC123DEF456",
            .secure: "TRUE"
        ]) {
            cookies.append(loginCookie)
        }
        
        // 使用者資訊 Cookie
        if let userCookie = HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: "user_info",
            .value: "user123",
            .secure: "TRUE"
        ]) {
            cookies.append(userCookie)
        }
        
        return cookies
    }
}
