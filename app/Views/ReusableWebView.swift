//
//  ReusableWebView.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2024/12/19.
//

import SwiftUI
import WebKit

/// 可重用的 WebView 元件
/// ✅ 雷點4修正：使用正確的 Coordinator 模式，避免 WebView 被重複建立或提早釋放
struct EnhancedWebView: UIViewRepresentable {
    
    // MARK: - Properties
    
    let url: URL?
    let html: String?
    let allowsBackForward: Bool
    let showsProgress: Bool
    let customUserAgent: String?
    let needLogin: Bool
    let identifier: String
    
    // MARK: - Callbacks
    
    var onProgress: ((Double) -> Void)?
    var onTitleChange: ((String?) -> Void)?
    var onOpenExternal: ((URL) -> Void)?
    
    // MARK: - Initializers
    
    init(
        url: URL? = nil,
        html: String? = nil,
        allowsBackForward: Bool = true,
        showsProgress: Bool = true,
        customUserAgent: String? = nil,
        needLogin: Bool = false,
        identifier: String = "default",
        onProgress: ((Double) -> Void)? = nil,
        onTitleChange: ((String?) -> Void)? = nil,
        onOpenExternal: ((URL) -> Void)? = nil
    ) {
        self.url = url
        self.html = html
        self.allowsBackForward = allowsBackForward
        self.showsProgress = showsProgress
        self.customUserAgent = customUserAgent
        self.needLogin = needLogin
        self.identifier = identifier
        self.onProgress = onProgress
        self.onTitleChange = onTitleChange
        self.onOpenExternal = onOpenExternal
    }
    
    // MARK: - UIViewRepresentable
    
    /// ✅ 雷點4修正：正確使用 makeCoordinator() 建立協調器
    /// Coordinator 會由 SwiftUI 自動管理生命週期
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // 使用池化的 WebView 避免重建
        let config = WebViewConfigFactory.createConfiguration(
            customUserAgent: customUserAgent,
            enableJSBridge: true
        )
        
        let webView = WebViewPool.shared.getWebView(for: identifier, config: config)
        
        // ✅ 設定協調器（使用 context.coordinator）
        let coordinator = context.coordinator
        coordinator.setupWebView(webView)
        
        // 設定 JS 橋接
        webView.configuration.userContentController.add(coordinator, name: "bridge")
        
        // 設定 WebView 屬性
        webView.allowsBackForwardNavigationGestures = allowsBackForward
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        
        // 設定下拉重整
        webView.scrollView.refreshControl = createRefreshControl(coordinator: coordinator)
        
        // ✅ 雷點1修正：在 makeUIView 就開始載入內容
        loadContent(in: webView, coordinator: coordinator)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        
        // 更新 callbacks
        coordinator.onProgress = onProgress
        coordinator.onTitleChange = onTitleChange
        coordinator.onOpenExternal = onOpenExternal
        
        // 只在 URL 真正改變時才載入，避免不必要的重載
        let shouldLoad: Bool
        
        if let url = url {
            // ✅ 雷點1修正：使用 absoluteString 比較更可靠
            let currentURLString = webView.url?.absoluteString ?? ""
            let targetURLString = url.absoluteString
            shouldLoad = currentURLString.isEmpty || (currentURLString != targetURLString && !webView.isLoading)
        } else if html != nil {
            shouldLoad = true // HTML 內容可能改變，需要重載
        } else {
            shouldLoad = false
        }
        
        guard shouldLoad else { return }
        
        loadContent(in: webView, coordinator: coordinator)
        }
    
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // 清理資源
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "bridge")
    }
    
    // MARK: - Private Methods
    
    private func loadContent(in webView: WKWebView, coordinator: Coordinator) {
        if let url = url {
            coordinator.loadURL(url, in: webView)
        } else if let html = html {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    private func createRefreshControl(coordinator: Coordinator) -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        return refreshControl
    }
    
    // MARK: - Coordinator
    /// ✅ 雷點4修正：使用內部 Coordinator 類別，正確管理 WebView 的生命週期
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: EnhancedWebView
        private weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?
        
        var onProgress: ((Double) -> Void)?
        var onTitleChange: ((String?) -> Void)?
        var onOpenExternal: ((URL) -> Void)?
        
        init(parent: EnhancedWebView) {
            self.parent = parent
            self.onProgress = parent.onProgress
            self.onTitleChange = parent.onTitleChange
            self.onOpenExternal = parent.onOpenExternal
            super.init()
        }
        
        func setupWebView(_ webView: WKWebView) {
            self.webView = webView
            webView.navigationDelegate = self
            webView.uiDelegate = self
            
            // 監聽進度變化
            progressObservation = webView.observe(\.estimatedProgress) { [weak self] webView, _ in
            DispatchQueue.main.async {
                    self?.onProgress?(webView.estimatedProgress)
                }
            }
        }
        
        func loadURL(_ url: URL, in webView: WKWebView) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
            // 延遲結束刷新動畫
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sender.endRefreshing()
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { [weak self] in
                self?.onTitleChange?(webView.title)
            }
        }
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let host = challenge.protectionSpace.host
            let trustedHosts = [
                "portal.nchu.edu.tw",
                "lms2020.nchu.edu.tw",
                "onepiece.nchu.edu.tw",
                "elearning.nchu.edu.tw",
                "www.lib.nchu.edu.tw"
            ]
            
            if trustedHosts.contains(host), let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "bridge" else { return }
            print("📱 收到 JS 訊息: \(message.body)")
        }
        
        deinit {
            progressObservation?.invalidate()
        }
    }
}

// MARK: - WebView Modifiers

extension EnhancedWebView {
    
    /// 設定進度回調
    func onProgressChange(_ handler: @escaping (Double) -> Void) -> EnhancedWebView {
        var copy = self
        copy.onProgress = handler
        return copy
    }
    
    /// 設定標題變更回調
    func onTitleUpdate(_ handler: @escaping (String?) -> Void) -> EnhancedWebView {
        var copy = self
        copy.onTitleChange = handler
        return copy
    }
    
    /// 設定外部連結處理
    func onOpenExternalURL(_ handler: @escaping (URL) -> Void) -> EnhancedWebView {
        var copy = self
        copy.onOpenExternal = handler
        return copy
    }
}
