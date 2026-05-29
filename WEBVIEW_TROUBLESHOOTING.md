# 🔧 WebView 第一次載入問題排查指南

## 🚨 問題現象
- 第一次點擊外部連結時，WebView 顯示空白或載入失敗
- 第二次點擊同樣連結時能正常載入

## 🔍 問題原因分析

### 1. **App Transport Security (ATS) 限制**
iOS 默認阻止不安全的 HTTP 連線，學校網站可能使用舊版 TLS 或自簽證書。

### 2. **網路初始化延遲**
首次網路請求需要初始化網路堆疊，造成延遲。

### 3. **SSL 憑證信任問題**
學校網站的 SSL 憑證可能需要特殊處理。

## ✅ 解決方案

### **方案 1：使用 SFSafariViewController（推薦）**

```swift
// 已實作於 SimpleWebView.swift
SimpleWebViewContainer(
    url: URL(string: "https://portal.nchu.edu.tw/")!,
    title: "興大入口",
    useSafari: true  // 使用 Safari（推薦）
)
```

**優點：**
- ✅ 系統自動處理 ATS 和 SSL 問題
- ✅ 完整的 Safari 功能和性能
- ✅ 無需額外配置

### **方案 2：配置 App Transport Security**

如果需要使用 WKWebView，需要在 **Xcode 專案設定** 中添加以下配置：

#### **在 Xcode 中設定：**
1. 選擇專案根目錄
2. 選擇 Target → Info
3. 在 "Custom iOS Target Properties" 添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>nchu.edu.tw</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### **方案 3：網路預熱機制（已實作）**

```swift
// 在 appApp.swift 中已加入預熱機制
private func preWarmWebView() {
    // 預先載入興大網站以初始化網路堆疊
    let preWarmWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    let request = URLRequest(url: URL(string: "https://www.nchu.edu.tw")!)
    preWarmWebView.load(request)
}
```

### **方案 4：改用直接開啟 Safari**

如果仍有問題，可以直接開啟系統 Safari：

```swift
// 直接在 Safari 中開啟
Button("興大入口") {
    if let url = URL(string: "https://portal.nchu.edu.tw/") {
        UIApplication.shared.open(url)
    }
}
```

## 🎯 目前實作的解決方案

### **已加入的改進：**

1. **✅ SFSafariViewController 優化**
   - 更好的配置選項
   - 載入失敗回調處理
   - 自動錯誤處理

2. **✅ 網路預熱機制**
   - App 啟動時預熱興大網站
   - 初始化網路堆疊
   - SSL 憑證預載

3. **✅ 備用方案**
   - 載入失敗時提供 Safari 開啟選項
   - 重試機制
   - 友善的錯誤提示

4. **✅ 增強的 SSL 處理**
   - 信任興大相關網域
   - 自動處理憑證問題

## 🧪 測試步驟

### **測試流程：**
1. 完全關閉 App
2. 重新啟動 App
3. 點擊「興大入口」或其他外部連結
4. 觀察是否立即載入

### **預期結果：**
- ✅ 第一次點擊立即載入
- ✅ 無空白畫面
- ✅ 載入失敗時顯示友善提示

## 🔄 如果問題仍然存在

### **進階調試：**

1. **檢查 Console 日誌**
   ```
   🌐 WebView 預熱請求已發送：興大官網
   🌐 WebView 預熱完成
   🌐 預熱網路連線：https://portal.nchu.edu.tw/
   ✅ 預熱成功 portal.nchu.edu.tw: HTTP 200
   ```

2. **使用 WKWebView 模式測試**
   ```swift
   SimpleWebViewContainer(
       url: url,
       title: title,
       useSafari: false  // 使用 WKWebView 進行調試
   )
   ```

3. **檢查網路連線**
   - 確保設備有穩定的網路連線
   - 嘗試在 Safari 中直接開啟相同連結

## 📋 建議使用方式

### **最佳實踐順序：**

1. **首選：SFSafariViewController** ✅
   - 適用於所有外部學校網站
   - 系統自動處理所有問題

2. **次選：WKWebView + ATS 配置**
   - 僅在需要深度整合時使用
   - 需要手動配置安全設定

3. **備選：直接開啟 Safari**
   - 最簡單可靠的方案
   - 用戶體驗稍差

---

**目前的實作已經包含了所有主要的解決方案，應該能解決第一次載入問題！** 🎉

