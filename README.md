# 初興 (NCHUHelper)

![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?style=for-the-badge&logo=swift&logoColor=white)
![iOS 17+](https://img.shields.io/badge/iOS-17.0+-black?style=for-the-badge&logo=apple)
![MVVM](https://img.shields.io/badge/Architecture-MVVM-orange?style=for-the-badge)
![Zero Dependencies](https://img.shields.io/badge/Dependencies-0-success?style=for-the-badge)

**初興 (NCHUHelper)** 是一款專為中興大學學生打造的 iOS 應用程式，旨在提供直覺、流暢的校園生活輔助。透過純原生的 SwiftUI 架構，實現了快速的課表規劃與校園大樓地圖導航，並且主打**離線優先**，將資料儲存於本地端，保護學生隱私並提供極速的操作體驗。

## ✨ 核心功能 (Features)

### 🗓 智慧課表規劃 (Schedule Planner)
- **視覺化課表網格**：直覺的 14x5 時間軸網格，支援拖放與即時編輯。
- **自動衝堂偵測**：即時分析並以顏色標記衝堂的課程，避免選課失誤。
- **空堂分析**：自動計算每週空檔，幫助學生更好規劃課外時間。
- **自訂課程**：支援手動新增課程、顏色標碼與類型分類。

### 🗺 校園地圖導航 (Campus Navigation)
- **大樓搜尋**：支援以建築物名稱、代碼或別名進行快速搜尋。
- **MapKit 整合**：直接在地圖上顯示中興大學各建築的精確座標。
- **第三方導航跳轉**：一鍵開啟 Apple Maps 或 Google Maps 進行路線規劃。
- **特約醫療院所**：內建中興大學特約診所地圖與清單。

## 🛠 技術棧 (Tech Stack)

本專案堅持使用 **零第三方依賴** 的純原生開發模式，以確保 App 的效能與穩定性：

- **語言/框架**: Swift 5.9, SwiftUI, MapKit
- **架構模式**: MVVM (Model-View-ViewModel)
- **非同步處理**: `async/await`, Combine (`@Published`, `ObservableObject`)
- **資料儲存**: 
  - `UserDefaults` (使用者偏好與課表)
  - `Codable` + 本地 JSON/CSV 解析 (課程庫與大樓資料)
- **網頁整合**: `WKWebView`, `SFSafariViewController` (具備預熱機制解決白畫面問題)

## 📂 目錄結構 (Folder Structure)

```text
/app
 ├── /Models         # 核心資料模型 (Course, Building, UserProfile)
 ├── /ViewModels     # 業務邏輯與狀態管理 (ScheduleVM, ThemeManager)
 ├── /Views          # SwiftUI 畫面視圖 (MainTabView, SchedulePlannerView)
 ├── /Utils          # 共用工具與擴充功能 (CSVImporter, CampusUtils)
 ├── /Data           # 資料讀取與快取層 (CourseDataStore)
 ├── /Resources      # 靜態資源檔案 (Buildings.json, CSV 檔)
 └── /Assets.xcassets # 圖片與顏色定義
```

## 🚀 如何運行 (How to Run)

1. 確認你的開發環境：
   - **Xcode**: 15.0 或以上版本
   - **macOS**: Sonoma (14.0) 或以上版本
   - **Target**: iOS 17.0+
2. Clone 專案到本地：
   ```bash
   git clone https://github.com/saaaacd/NCHU-app-iot-final.git
   ```
3. 打開專案：
   - 雙擊打開 `app.xcodeproj`。
4. 選擇模擬器 (例如 iPhone 15 Pro) 並按下 `Cmd + R` 編譯運行。

## 🤝 貢獻 (Contributing)

這是一個以學習與校園服務為出發點的專案，歡迎任何有興趣的開發者發起 Pull Request 或提出 Issues！

## 📄 授權 (License)

This project is licensed under the MIT License - see the LICENSE file for details.
