//
//  SimpleWebView.swift
//  初興 (NCHUHelper)
//
//  Created by 劉李陽 on 2025/9/28.
//  Updated by AI Assistant on 2024/12/19.
//  參考 NUK App 的最佳實踐：優先使用 SFSafariViewController
//  集成了新的 WebView 架構和 Cookie 管理
//

import SwiftUI
import SafariServices
import WebKit

// MARK: - Safari Web View (推薦用法)
struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        // 配置 SFSafariViewController
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.delegate = context.coordinator
        
        // 設定樣式
        safariVC.preferredBarTintColor = UIColor.systemBackground
        safariVC.preferredControlTintColor = UIColor.systemBlue
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // SFSafariViewController 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariWebView
        
        init(_ parent: SafariWebView) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.dismiss()
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if !didLoadSuccessfully {
                print("⚠️ Safari 載入失敗：\(parent.url.absoluteString)")
            }
        }
    }
}

// MARK: - 簡單 WKWebView Wrapper（僅在需要深度整合時使用）
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var title: String
    
    // 追蹤已載入的 URL，避免重複載入
    @State private var lastLoadedURL: URL?
    
    init(url: URL, 
         isLoading: Binding<Bool> = .constant(false),
         canGoBack: Binding<Bool> = .constant(false), 
         canGoForward: Binding<Bool> = .constant(false),
         title: Binding<String> = .constant("")) {
        self.url = url
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._title = title
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // 使用新的配置工廠
        let config = WebViewConfigFactory.campusConfiguration
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // ✅ 雷點1修正：在 makeUIView 中就載入 URL，確保 WebView 一建立就開始載入
        // 這樣可以避免第一次顯示空白的問題
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // ✅ 雷點1修正：改用 absoluteString 比較，更可靠
        // 只在 URL 真正改變時才重新載入，避免不必要的刷新
        let currentURLString = webView.url?.absoluteString ?? ""
        let targetURLString = url.absoluteString
        
        // 如果當前沒有載入任何頁面，或 URL 真的改變了，才載入
        if currentURLString.isEmpty || (currentURLString != targetURLString && !webView.isLoading) {
            webView.load(URLRequest(url: url))
        }
    }
    
    static func dismantleUIView(_ webView: WKWebView, coordinator: ()) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.title = webView.title ?? ""
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
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
        
        // 處理新窗口
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

// MARK: - 簡單 WebView 容器（帶工具欄）
struct SimpleWebViewContainer: View {
    let url: URL
    let title: String
    let useSafari: Bool
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var webTitle = ""
    @State private var webView: WKWebView?
    @State private var showingSafariError = false
    @State private var hasPrewarmed = false
    
    init(url: URL, title: String, useSafari: Bool = true) {
        self.url = url
        self.title = title
        self.useSafari = useSafari
    }
    
    var body: some View {
        if useSafari {
            // 推薦：使用 SFSafariViewController
            SafariWebView(url: url)
                .onAppear {
                    // 預熱網路連線
                    prewarmNetworkConnection()
                }
                .alert("載入失敗", isPresented: $showingSafariError) {
                    Button("在瀏覽器中開啟") {
                        UIApplication.shared.open(url)
                        dismiss()
                    }
                    Button("重試") {
                        // 重新載入
                    }
                    Button("取消", role: .cancel) {
                        dismiss()
                    }
                } message: {
                    Text("無法載入網頁，請檢查網路連線或在瀏覽器中開啟")
                }
        } else {
            // 備選：自定義 WKWebView（僅在需要深度整合時使用）
            NavigationView {
                VStack(spacing: 0) {
                    // 載入指示器
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle(tint: theme.accent.color))
                            .scaleEffect(x: 1, y: 0.5)
                    }
                    
                    // WebView
                    WebView(
                        url: url,
                        isLoading: $isLoading,
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        title: $webTitle
                    )
                    .onAppear {
                        // 獲取 webView 實例以便控制
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                webView = findWebView(in: window)
                            }
                        }
                    }
                    
                    // 簡單工具欄
                    HStack {
                        Button(action: { webView?.goBack() }) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(canGoBack ? theme.accent.color : .gray)
                        }
                        .disabled(!canGoBack)
                        
                        Spacer()
                        
                        Button(action: { webView?.goForward() }) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(canGoForward ? theme.accent.color : .gray)
                        }
                        .disabled(!canGoForward)
                        
                        Spacer()
                        
                        Button(action: { webView?.reload() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(theme.accent.color)
                        }
                        
                        Spacer()
                        
                        Button(action: { UIApplication.shared.open(url) }) {
                            Image(systemName: "safari")
                                .foregroundStyle(theme.accent.color)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                }
                .navigationTitle(webTitle.isEmpty ? title : webTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") { dismiss() }
                            .foregroundStyle(theme.accent.color)
                    }
                }
            }
        }
    }
    
    // Helper function
    private func findWebView(in view: UIView) -> WKWebView? {
        if let webView = view as? WKWebView {
            return webView
        }
        for subview in view.subviews {
            if let webView = findWebView(in: subview) {
                return webView
            }
        }
        return nil
    }
    
    // MARK: - 網路預熱機制
    private func prewarmNetworkConnection() {
        guard !hasPrewarmed else { return }
        hasPrewarmed = true
        
        print("🌐 預熱網路連線：\(url.absoluteString)")
        
        // 發送 HEAD 請求預熱連線
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ 預熱失敗：\(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ 預熱成功：HTTP \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}

// MARK: - Preview
#Preview {
    Group {
        // 推薦用法：SFSafariViewController
        SimpleWebViewContainer(
            url: URL(string: "https://portal.nchu.edu.tw/")!,
            title: "興大入口",
            useSafari: true
        )
        .environmentObject(ThemeManager())
        
        // 備選用法：自定義 WKWebView
        SimpleWebViewContainer(
            url: URL(string: "https://portal.nchu.edu.tw/")!,
            title: "興大入口",
            useSafari: false
        )
        .environmentObject(ThemeManager())
    }
}
