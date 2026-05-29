//
//  WebViewCoordinator.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2024/12/19.
//

import Foundation
import WebKit
import SwiftUI
import SafariServices
import Combine

/// WebView 協調器，處理所有 WebKit 委託方法
@MainActor
final class WebViewCoordinator: NSObject, ObservableObject {
    
    static let shared = WebViewCoordinator()
    
    // MARK: - Published Properties
    
    @Published var progress: Double = 0.0
    @Published var title: String?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var currentURL: URL?
    @Published var errorState: WebViewError?
    
    // MARK: - Callbacks
    
    var onProgress: ((Double) -> Void)?
    var onTitleChange: ((String?) -> Void)?
    var onOpenExternal: ((URL) -> Void)?
    var onDecidePolicy: ((URL) -> NavigationPolicy)?
    var onLoadFinished: (() -> Void)?
    var onLoadFailed: ((Error) -> Void)?
    
    // MARK: - Private Properties
    
    private weak var webView: WKWebView?
    private var progressObservation: NSKeyValueObservation?
    private var reloadAttempts = 0
    private let maxReloadAttempts = 3
    
    override init() {
        super.init()
    }
    
    // MARK: - Setup
    
    func setupWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // 監聽進度變化
        progressObservation = webView.observe(\.estimatedProgress) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.progress = webView.estimatedProgress
                self?.onProgress?(webView.estimatedProgress)
            }
        }
        
        // 更新狀態
        updateStates()
    }
    
    // MARK: - Public Methods
    
    @objc func reload() {
        webView?.reload()
        errorState = nil
        reloadAttempts += 1
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func loadURL(_ url: URL) {
        guard let webView = webView else { return }
        
        // 清除錯誤狀態
        errorState = nil
        reloadAttempts = 0
        
        // 載入前檢查是否需要注入 Cookies
        Task { @MainActor in
            do {
                try await CookieStore.shared.loadSSOCookies(for: url)
            } catch {
                print("⚠️ Cookie 載入失敗，繼續載入頁面: \(error)")
            }
            
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    private func updateStates() {
        guard let webView = webView else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.canGoBack = webView.canGoBack
            self?.canGoForward = webView.canGoForward
            self?.title = webView.title
            self?.currentURL = webView.url
            self?.onTitleChange?(webView.title)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error, url: URL?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let webError = WebViewError.from(error, url: url)
            self.errorState = webError
            self.onLoadFailed?(error)
            
            print("❌ WebView 載入失敗: \(webError.localizedDescription)")
            
            // 自動重試機制（僅對特定錯誤類型）
            if self.shouldAutoRetry(error: webError) && self.reloadAttempts < self.maxReloadAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.reload()
                }
            }
        }
    }
    
    private func shouldAutoRetry(error: WebViewError) -> Bool {
        switch error {
        case .networkError, .timeout:
            return true
        default:
            return false
        }
    }
    
    deinit {
        progressObservation?.invalidate()
    }
}

// MARK: - WKNavigationDelegate

extension WebViewCoordinator: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // 檢查是否為外部連結
        if let policy = onDecidePolicy?(url) {
            switch policy {
            case .allow:
                decisionHandler(.allow)
            case .cancel:
                decisionHandler(.cancel)
            case .openInSafari:
                decisionHandler(.cancel)
                onOpenExternal?(url)
            }
            return
        }
        
        // 預設策略：外部連結用 Safari 開啟
        if shouldOpenInSafari(url: url) {
            decisionHandler(.cancel)
            onOpenExternal?(url)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorState = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.updateStates()
            self?.reloadAttempts = 0
            self?.onLoadFinished?()
            
            // 檢查白屏問題
            self?.checkForBlankPage(webView)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error, url: webView.url)
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error, url: webView.url)
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("🔄 頁面重導向: \(webView.url?.absoluteString ?? "unknown")")
        updateStates()
    }
    
    // 處理 SSL 證書（學校網站常見問題）
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // 檢查是否為信任的學校網域
        let host = challenge.protectionSpace.host
        let trustedHosts = [
            "portal.nchu.edu.tw",
            "lms2020.nchu.edu.tw", 
            "onepiece.nchu.edu.tw",
            "elearning.nchu.edu.tw",
            "www.lib.nchu.edu.tw",
            "ccnet.nchu.edu.tw",
            "mail.nchu.edu.tw",
            "dorm.nchu.edu.tw"
        ]
        
        if trustedHosts.contains(host) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    // 檢查白屏問題
    private func checkForBlankPage(_ webView: WKWebView) {
        // 延遲檢查，給頁面時間載入
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let hasTitle = !(webView.title?.isEmpty ?? true)
            let hasValidURL = webView.url?.absoluteString.contains("about:blank") == false
            
            if !hasTitle && !hasValidURL && self.reloadAttempts < self.maxReloadAttempts {
                print("⚠️ 偵測到可能的白屏，嘗試重新載入...")
                self.reload()
            }
        }
    }
    
    private func shouldOpenInSafari(url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        
        // 外部連結域名列表
        let externalDomains = [
            "google.com", "youtube.com", "facebook.com", "instagram.com",
            "line.me", "github.com", "stackoverflow.com"
        ]
        
        return externalDomains.contains { host.contains($0) }
    }
}

// MARK: - WKUIDelegate

extension WebViewCoordinator: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        // 在主執行緒顯示 Alert
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "網頁訊息", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in
                completionHandler()
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "確認", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in
                completionHandler(true)
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler(false)
            }
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        // 處理 window.open()，改在當前 WebView 載入
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewCoordinator: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard message.name == "bridge" else { return }
        
        print("📱 收到 JS 訊息: \(message.body)")
        
        // 解析 JS 訊息
        if let messageDict = message.body as? [String: Any],
           let action = messageDict["action"] as? String {
            
            handleJSMessage(action: action, data: messageDict)
        }
    }
    
    private func handleJSMessage(action: String, data: [String: Any]) {
        DispatchQueue.main.async {
            switch action {
            case "openCourse":
                if let courseId = data["id"] as? String {
                    print("🎓 開啟課程: \(courseId)")
                    // 這裡可以觸發導航到課程詳情頁面
                }
                
            case "showAlert":
                if let message = data["message"] as? String {
                    self.showAlert(message: message)
                }
                
            case "openExternal":
                if let urlString = data["url"] as? String,
                   let url = URL(string: urlString) {
                    self.onOpenExternal?(url)
                }
                
            default:
                print("⚠️ 未知的 JS 動作: \(action)")
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "來自網頁的訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// MARK: - Supporting Types

enum NavigationPolicy {
    case allow
    case cancel
    case openInSafari
}

enum WebViewError: LocalizedError {
    case networkError(String)
    case timeout
    case sslError
    case notFound
    case serverError(Int)
    case unknown(String)
    
    static func from(_ error: Error, url: URL?) -> WebViewError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkError("網路連線問題")
        case NSURLErrorServerCertificateUntrusted, NSURLErrorSecureConnectionFailed:
            return .sslError
        case NSURLErrorBadURL, NSURLErrorUnsupportedURL:
            return .notFound
        default:
            if nsError.code >= 400 && nsError.code < 500 {
                return .serverError(nsError.code)
            }
            return .unknown(error.localizedDescription)
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .timeout:
            return "載入超時，請檢查網路連線"
        case .sslError:
            return "SSL 憑證錯誤"
        case .notFound:
            return "找不到網頁"
        case .serverError(let code):
            return "伺服器錯誤 (\(code))"
        case .unknown(let message):
            return "未知錯誤: \(message)"
        }
    }
}
