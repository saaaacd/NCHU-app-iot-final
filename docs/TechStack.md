# NCHUHelper 技術棧說明

## 前端框架

### SwiftUI
- **用途**：所有 UI 畫面使用 SwiftUI 宣告式語法
- **代表性檔案**：
  - `app/Views/MainTabView.swift` - 主 Tab 視圖
  - `app/Views/SchedulePlannerView.swift` - 課表網格視圖
  - `app/Views/CampusMapView.swift` - 地圖視圖
- **關鍵類別/函式**：
  - `@ViewBuilder` - 組合多個子視圖
  - `@State` / `@StateObject` / `@ObservedObject` - 狀態管理
  - `NavigationStack` - 導航容器
  - `TabView` - Tab 切換

---

## 架構模式

### MVVM (Model-View-ViewModel)
- **用途**：分離 UI 與業務邏輯
- **代表性檔案**：
  - **View**：`app/Views/SchedulePlannerView.swift`
  - **ViewModel**：`app/ViewModels/ScheduleVM.swift`
  - **Model**：`app/Models/Course.swift`
- **關鍵類別/函式**：
  - `@MainActor final class ScheduleVM: ObservableObject` - ViewModel 標記
  - `@Published var courses: [Course]` - 可觀察屬性
  - `@ObservedObject var scheduleVM: ScheduleVM` - View 綁定 ViewModel

### ObservableObject / Combine
- **用途**：響應式資料流，View 自動更新
- **代表性檔案**：
  - `app/ViewModels/ScheduleVM.swift` - `@Published` 屬性
  - `app/ViewModels/ThemeManager.swift` - 主題變更通知
- **關鍵類別/函式**：
  - `@Published` - 自動觸發 View 更新
  - `ObservableObject` - Combine 協議

### async-await
- **用途**：非同步資料載入，避免阻塞主執行緒
- **代表性檔案**：
  - `app/Data/CourseDataStore.swift` - `loadCourses()` async
  - `app/Data/BuildingStore.swift` - `loadBuildingsData() async throws`
- **關鍵類別/函式**：
  - `func loadCourses() async` - 非同步函式
  - `Task { await loadCourses() }` - 建立非同步任務
  - `try await withCheckedThrowingContinuation` - 非同步回調

---

## 網路/資料取得

### URLSession
**（未在程式碼中找到直接使用 URLSession，WebView 使用 WKWebView）**

### HTML 解析
**（未在程式碼中找到 HTML 解析，使用 WebView 直接顯示網頁）**

### API
**（未在程式碼中找到 API 呼叫，所有資料來自本地檔案）**

### JSON
- **用途**：建築物資料、醫療優惠資料儲存格式
- **代表性檔案**：
  - `app/Resources/Buildings.json` - 建築物座標資料
  - `app/Data/BuildingStore.swift` - JSON 解析
- **關鍵類別/函式**：
  - `JSONDecoder().decode([Building].self, from: data)` - JSON 解碼
  - `Building: Codable` - 模型實作 Codable 協議

### CSV 解析
- **用途**：課程資料、醫療優惠資料解析
- **代表性檔案**：
  - `app/Utils/CSVImporter.swift` - CSV 解析工具
  - `app/Data/CourseDataStore.swift` - 課程 CSV 載入
  - `app/Data/MedicalDiscountStore.swift` - 醫療優惠 CSV 載入
- **關鍵類別/函式**：
  - `CSVImporter.parseCourses(from: Data)` - CSV 解析
  - `parseCSVLine(_ line: String)` - 處理引號與逗號

---

## 資料儲存與快取

### UserDefaults
- **用途**：儲存使用者設定、個人課表、主題設定
- **代表性檔案**：
  - `app/ViewModels/ScheduleVM.swift` - 課表儲存
  - `app/ViewModels/ThemeManager.swift` - 主題設定儲存
  - `app/ViewModels/AvatarManager.swift` - 頭像選擇儲存
- **關鍵類別/函式**：
  - `UserDefaults.standard.set(data, forKey: "SavedCourses")` - 儲存
  - `UserDefaults.standard.data(forKey: "SavedCourses")` - 讀取
  - `UserDefaults.standard.bool(forKey: "isDarkMode")` - 布林值讀取

### Bundle Resources
- **用途**：靜態資料檔案（CSV、JSON、PDF）
- **代表性檔案**：
  - `app/Resources/Buildings.json` - 建築物資料
  - `app/Resources/nchu_courses_complete_2024.csv` - 課程資料
  - `app/Resources/114學年度行事曆.pdf` - 行事曆 PDF
- **關鍵類別/函式**：
  - `Bundle.main.url(forResource: "Buildings", withExtension: "json")` - 取得資源 URL
  - `Bundle.main.path(forResource: fileName, ofType: "csv")` - 取得資源路徑

### 檔案系統
**（未在程式碼中找到直接寫入檔案系統，使用 UserDefaults 與 Bundle）**

### 資料庫
**（未在程式碼中找到資料庫，使用 UserDefaults 與 Bundle Resources）**

---

## 地圖

### MapKit
- **用途**：顯示校園地圖、建築物標記
- **代表性檔案**：
  - `app/Views/CampusMapView.swift` - 地圖視圖
  - `app/Views/MedicalDiscountMapView.swift` - 醫療優惠地圖
- **關鍵類別/函式**：
  - `MKMapView` - 地圖視圖
  - `MKCoordinateRegion` - 地圖區域
  - `MKAnnotation` - 標記協議
  - `BuildingAnnotation` - 自訂標記類別

### 標記 (Annotation)
- **用途**：在地圖上顯示建築物位置
- **代表性檔案**：
  - `app/Views/CampusMapView.swift:13` - `BuildingAnnotation`
  - `app/Views/MedicalDiscountMapView.swift` - `MedicalDiscountAnnotation`
- **關鍵類別/函式**：
  - `class BuildingAnnotation: NSObject, MKAnnotation` - 標記類別
  - `mapView.addAnnotations(newAnnotations)` - 新增標記

### 定位
**（未在程式碼中找到定位功能，地圖使用固定中心點）**

### 導航
- **用途**：開啟 Apple Maps / Google Maps 導航
- **代表性檔案**：
  - `app/Utils/CampusUtils.swift` - 導航工具
  - `app/Models/Building.swift` - 導航 URL 生成
- **關鍵類別/函式**：
  - `CampusUtils.openGoogleMap(for: Building)` - 開啟導航
  - `Building.appleMapURL()` - Apple Maps URL
  - `Building.googleMapURL()` - Google Maps URL

---

## WebView 整合

### SFSafariViewController
- **用途**：安全開啟校務網站（推薦方式）
- **代表性檔案**：
  - `app/Views/SimpleWebView.swift:16` - `SafariWebView`
- **關鍵類別/函式**：
  - `SFSafariViewController(url: URL, configuration: config)` - 建立 Safari 視圖
  - `SFSafariViewControllerDelegate` - 載入狀態監聽

### WKWebView
- **用途**：深度整合 WebView（需要更多控制時使用）
- **代表性檔案**：
  - `app/Views/SimpleWebView.swift:65` - `WebView`
  - `app/Views/ReusableWebView.swift` - 進階 WebView
- **關鍵類別/函式**：
  - `WKWebView` - WebKit 視圖
  - `WKWebViewConfiguration` - WebView 設定
  - `WKWebsiteDataStore` - Cookie 管理

### WebView 預熱
- **用途**：解決首次載入白畫面問題
- **代表性檔案**：
  - `app/appApp.swift:36` - `preWarmWebView()`
- **關鍵類別/函式**：
  - `WKWebView` 預先載入興大首頁
  - 觸發網路權限與 SSL 憑證預載

---

## 工程化

### Git
**（未在程式碼中找到 Git 相關設定，但專案應有版本控制）**

### 模組化
- **目錄結構**：
  - `/Models` - 資料模型
  - `/ViewModels` - 業務邏輯
  - `/Views` - UI 畫面
  - `/Utils` - 工具函式
  - `/Data` - 資料載入與儲存
  - `/Resources` - 靜態資源

### 測試
- **單元測試**：
  - `appTests/ScheduleVMTests.swift` - ViewModel 測試
- **UI 測試**：
  - `appUITests/appUITests.swift` - UI 自動化測試
- **關鍵類別/函式**：
  - `XCTestCase` - 測試基類
  - `XCTAssertEqual` - 斷言

### CI/CD
**（未在程式碼中找到 CI/CD 設定）**

---

## 其他技術

### Swift 5.9
- **用途**：主要程式語言
- **特性使用**：
  - `async/await` - 非同步程式設計
  - `@MainActor` - 主執行緒標記
  - `Codable` - JSON/CSV 編解碼

### Combine Framework
- **用途**：響應式程式設計（透過 ObservableObject）
- **代表性檔案**：
  - `app/ViewModels/ScheduleVM.swift` - `@Published` 屬性

### UIKit 整合
- **用途**：WebView、分享功能需要 UIKit
- **代表性檔案**：
  - `app/Views/SimpleWebView.swift` - `UIViewRepresentable`
  - `app/Utils/ShareSheet.swift` - `UIViewControllerRepresentable`

### NotificationCenter
- **用途**：跨 View 通訊（課表跳轉地圖）
- **代表性檔案**：
  - `app/Views/MainTabView.swift:56` - `onReceive(.navigateToCampusMap)`
- **關鍵類別/函式**：
  - `NotificationCenter.default.post(name:object:userInfo:)` - 發送通知
  - `NotificationCenter.default.publisher(for:)` - 訂閱通知

---

## 技術亮點總結

1. **純 SwiftUI + MVVM**：無第三方依賴，使用原生框架
2. **async/await**：現代非同步程式設計，避免回調地獄
3. **Codable 協議**：自動 JSON/CSV 編解碼，減少手動解析
4. **單例模式**：`CourseDataStore.shared` 確保資料一致性
5. **WebView 預熱**：解決首次載入問題，提升使用者體驗
6. **離線優先**：所有資料本地儲存，保護隱私

---

*最後更新：2025-01-23*



