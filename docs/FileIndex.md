# NCHUHelper 專案檔案索引

## 最重要的檔案（15-30 個）

### App 入口與主要架構

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/appApp.swift` | App 入口點，初始化 ThemeManager 與 WebView 預熱 | 全功能 |
| `app/Views/MainTabView.swift` | 主 Tab 視圖，包含 5 個 Tab（主畫面/課表/排課助手/校園地圖/常用功能） | 全功能 |

### 課表相關

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/Views/SchedulePlannerView.swift` | 課表網格視圖，顯示課程、支援新增/編輯、衝堂標示 | 課表 |
| `app/ViewModels/ScheduleVM.swift` | 課表 ViewModel，管理課程資料、衝堂偵測、空檔計算、資料持久化 | 課表 |
| `app/Models/Course.swift` | 課程資料模型，支援多時段、必選通識分類 | 課表 |
| `app/Data/CourseDataStore.swift` | 課程資料載入與快取（單例），從 CSV 檔案載入所有課程 | 課表 |
| `app/Utils/CSVImporter.swift` | CSV 檔案解析工具，支援新舊兩種格式 | 課表 |
| `app/Utils/ScheduleExporter.swift` | 課表匯出工具（CSV/iCal/圖片） | 課表 |
| `app/Utils/FreeSlotFormatter.swift` | 空檔時間格式化工具 | 課表 |

### 空堂排課相關

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/Views/SmartCourseRecommendationView.swift` | 空堂排課視圖，選擇空堂時間後篩選通識課程 | 空堂排課 |
| `app/ViewModels/CourseRecommendationEngine.swift` | 課程推薦引擎，處理一鍵匯入系上課程與通識推薦 | 空堂排課 |
| `app/Views/CoursePickerView.swift` | 課程選擇器，從 CourseDataStore 選擇課程加入課表 | 空堂排課 |
| `app/Views/GeneralEducationCoursesView.swift` | 通識課程瀏覽視圖 | 空堂排課 |

### 校園地圖相關

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/Views/CampusMapView.swift` | 校園地圖視圖，使用 MapKit 顯示建築物標記 | 校園地圖 |
| `app/Views/CampusSearchView.swift` | 校園建築物搜尋視圖，支援關鍵字搜尋與導航 | 校園地圖 |
| `app/Data/BuildingStore.swift` | 建築物資料載入與搜尋，從 JSON 檔案載入 | 校園地圖 |
| `app/Models/Building.swift` | 建築物資料模型，包含座標、別名、導航 URL | 校園地圖 |
| `app/Utils/CampusUtils.swift` | 校園功能工具，處理 Google Maps / Apple Maps 導航 | 校園地圖 |
| `app/Resources/Buildings.json` | 建築物座標資料（64 個建築物） | 校園地圖 |

### WebView 整合相關

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/Views/SimpleWebView.swift` | WebView 整合（SFSafariViewController / WKWebView） | 整合校務網站 |
| `app/Views/ReusableWebView.swift` | 進階 WebView，支援 Cookie 管理與載入狀態 | 整合校務網站 |

### 其他功能相關

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/Views/MedicalDiscountView.swift` | 特約醫療院所列表視圖 | 其他功能 |
| `app/Data/MedicalDiscountStore.swift` | 醫療優惠資料載入，從 CSV 檔案載入 | 其他功能 |
| `app/Views/CalendarView.swift` | 行事曆視圖，顯示 114 學年度行事曆 PDF | 其他功能 |
| `app/Views/UserProfileView.swift` | 個人資料視圖，設定系所/年級/頭像 | 其他功能 |
| `app/ViewModels/ThemeManager.swift` | 主題管理（深色模式、主題色彩），使用 UserDefaults 持久化 | 其他功能 |
| `app/ViewModels/AvatarManager.swift` | 頭像管理，支援自訂頭像與預設樣式 | 其他功能 |

### 工具與資源

| 路徑 | 作用一句話 | 相關功能 |
|------|-----------|---------|
| `app/Utils/ShareSheet.swift` | 分享功能（UIActivityViewController） | 工具 |
| `app/Utils/ScheduleImageRenderer.swift` | 課表圖片渲染工具，將 SwiftUI 視圖轉為 UIImage | 工具 |
| `app/Resources/nchu_courses_complete_2024.csv` | 完整課程資料 CSV 檔 | 資源 |
| `app/Resources/gened_courses_complete.csv` | 通識課程資料 CSV 檔 | 資源 |

---

## 檔案分類統計

### 按功能分類

- **課表功能**：7 個檔案
  - SchedulePlannerView.swift
  - ScheduleVM.swift
  - Course.swift
  - CourseDataStore.swift
  - CSVImporter.swift
  - ScheduleExporter.swift
  - FreeSlotFormatter.swift

- **空堂排課功能**：4 個檔案
  - SmartCourseRecommendationView.swift
  - CourseRecommendationEngine.swift
  - CoursePickerView.swift
  - GeneralEducationCoursesView.swift

- **校園地圖功能**：6 個檔案
  - CampusMapView.swift
  - CampusSearchView.swift
  - BuildingStore.swift
  - Building.swift
  - CampusUtils.swift
  - Buildings.json

- **整合校務網站功能**：2 個檔案
  - SimpleWebView.swift
  - ReusableWebView.swift

- **其他功能**：6 個檔案
  - MedicalDiscountView.swift
  - MedicalDiscountStore.swift
  - CalendarView.swift
  - UserProfileView.swift
  - ThemeManager.swift
  - AvatarManager.swift

- **工具與資源**：4 個檔案
  - ShareSheet.swift
  - ScheduleImageRenderer.swift
  - nchu_courses_complete_2024.csv
  - gened_courses_complete.csv

### 按架構層分類

- **Presentation Layer (Views)**：15 個檔案
- **Domain Layer (ViewModels)**：4 個檔案
- **Data Layer (Stores / Utils)**：8 個檔案
- **Models**：3 個檔案
- **Resources**：10+ 個檔案（CSV、JSON、PDF）

---

## 關鍵依賴關係

### 資料流依賴

```
Resources (CSV/JSON)
    ↓
Data Layer (Stores)
    ↓
Domain Layer (ViewModels)
    ↓
Presentation Layer (Views)
```

### 具體依賴鏈

1. **課表資料流**：
   - `Resources/*.csv` → `CourseDataStore` → `ScheduleVM` → `SchedulePlannerView`

2. **建築物資料流**：
   - `Resources/Buildings.json` → `BuildingStore` → `CampusMapView` / `CampusSearchView`

3. **主題設定流**：
   - `UserDefaults` → `ThemeManager` → 所有 View（透過 `@EnvironmentObject`）

4. **WebView 整合流**：
   - `MainTabView` → `SimpleWebViewContainer` → `SFSafariViewController` / `WKWebView`

---

## 檔案命名規範

### Views
- 以 `View` 結尾：`SchedulePlannerView.swift`、`CampusMapView.swift`

### ViewModels
- 以 `VM` 或 `Manager` 結尾：`ScheduleVM.swift`、`ThemeManager.swift`

### Stores
- 以 `Store` 結尾：`CourseDataStore.swift`、`BuildingStore.swift`

### Utils
- 以功能命名：`CSVImporter.swift`、`ScheduleExporter.swift`、`CampusUtils.swift`

### Models
- 單數名詞：`Course.swift`、`Building.swift`

---

## 未在專案中找到但可能存在的檔案

- [ ] `Info.plist` - App 設定檔（權限、URL Schemes）
- [ ] `Assets.xcassets` - 圖片資源（已在專案中，但未詳細列出）
- [ ] 測試檔案（`appTests/`、`appUITests/` 已存在，但未詳細列出）

---

*最後更新：2025-01-23*



