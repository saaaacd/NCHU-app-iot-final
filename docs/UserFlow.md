# NCHUHelper 使用流程文件

## 主流程 Flow（箭頭版）

### 第一次使用流程
```
App 啟動
    ↓
MainTabView (Tab 0: 主畫面)
    ↓
HomeTabView
    ↓
[選擇頭像] → AvatarPickerView → UserProfileView (設定系所/年級)
    ↓
[返回主畫面]
```

### 登入/授權流程
**（未在程式碼中找到登入功能，App 為離線使用，無需登入）**

### 匯入課表流程
```
SchedulePlannerView (Tab 1: 課表)
    ↓
[匯入 CSV] → fileImporter
    ↓
CSVImporter.parseCourses()
    ↓
ScheduleVM.addCourse() (批次加入)
    ↓
[顯示警告] (若有解析錯誤)
    ↓
[自動儲存] → UserDefaults
```

### 看課表流程
```
SchedulePlannerView
    ↓
TimetableGridView (網格視圖)
    ↓
[顯示課程] → CourseBlock (顏色標識：必修/選修/通識)
    ↓
[點擊課程] → CourseDetailView (詳情)
    ↓
[編輯模式] → CourseFormView (修改課程)
```

### 查地圖流程
```
CampusSearchView (Tab 3: 校園地圖)
    ↓
[搜尋建築物] → BuildingStore.search()
    ↓
[顯示結果列表]
    ↓
[點擊建築物] → [Apple Maps] / [Google Maps]
    ↓
CampusUtils.openGoogleMap() → 開啟導航
```

**或從課表跳轉：**
```
SchedulePlannerView
    ↓
[點擊教室代號] → NotificationCenter.post(.navigateToCampusMap)
    ↓
MainTabView.onReceive() → selectedTab = 3
    ↓
CampusSearchView → 自動搜尋該建築物
```

### 空堂排課流程
```
CourseAssistantView (Tab 2: 排課助手)
    ↓
[空堂排課] → SmartCourseRecommendationView
    ↓
[選擇星期] → selectedDay
    ↓
[選擇節次] → selectedPeriods (可多選)
    ↓
[自動篩選] → filterCourses()
    ↓
[顯示推薦課程] → RecommendedCourseCard
    ↓
[查看詳情] → CourseDetailView
    ↓
[加入課表] → scheduleVM.addCourse()
```

### 收藏/搜尋流程
**（未在程式碼中找到收藏功能）**

**搜尋流程：**
```
CampusSearchView
    ↓
[輸入關鍵字] → searchText
    ↓
BuildingStore.search(matching: keyword)
    ↓
[即時過濾] → filteredBuildings
    ↓
[顯示結果]
```

### 設定流程
```
UtilitiesView (Tab 4: 常用功能)
    ↓
[個人資料] → UserProfileView
    ↓
[主題設定] → ThemeSettingsView
    ↓
[深色模式] → ThemeManager.toggleDarkMode()
    ↓
[主題色彩] → ThemeManager.updateAccentColor()
    ↓
[儲存] → UserDefaults
```

---

## 每個流程對應到的畫面/檔案

### 第一次使用
| 流程步驟 | 畫面/檔案 | 說明 |
|---------|----------|------|
| App 啟動 | `app/appApp.swift` | `NCHUHelperApp` 初始化 |
| 主畫面 | `app/Views/MainTabView.swift` | `HomeTabView` |
| 頭像選擇 | `app/Views/MainTabView.swift` | `AvatarPickerView` (sheet) |
| 個人資料 | `app/Views/UserProfileView.swift` | 設定系所/年級 |

### 匯入課表
| 流程步驟 | 畫面/檔案 | Store/Service |
|---------|----------|--------------|
| 匯入按鈕 | `app/Views/SchedulePlannerView.swift` | - |
| CSV 解析 | `app/Utils/CSVImporter.swift` | `CSVImporter.parseCourses()` |
| 加入課表 | `app/ViewModels/ScheduleVM.swift` | `ScheduleVM.addCourse()` |
| 資料儲存 | `app/ViewModels/ScheduleVM.swift` | `ScheduleVM.saveCourses()` |

### 看課表
| 流程步驟 | 畫面/檔案 | ViewModel |
|---------|----------|-----------|
| 課表網格 | `app/Views/SchedulePlannerView.swift` | `ScheduleVM` |
| 課程區塊 | `app/Views/SchedulePlannerView.swift` | `TimetableGridView` |
| 課程詳情 | `app/Views/CourseDetailView.swift` | - |
| 編輯表單 | `app/Views/CourseFormView.swift` | `ScheduleVM` |

### 查地圖
| 流程步驟 | 畫面/檔案 | Store/Service |
|---------|----------|--------------|
| 地圖搜尋 | `app/Views/CampusSearchView.swift` | `BuildingStore` |
| 地圖顯示 | `app/Views/CampusMapView.swift` | `BuildingStore` |
| 導航開啟 | `app/Utils/CampusUtils.swift` | `CampusUtils.openGoogleMap()` |

### 空堂排課
| 流程步驟 | 畫面/檔案 | Store/Service |
|---------|----------|--------------|
| 空堂選擇 | `app/Views/SmartCourseRecommendationView.swift` | - |
| 課程篩選 | `app/Views/SmartCourseRecommendationView.swift` | `CourseDataStore.shared` |
| 推薦顯示 | `app/Views/SmartCourseRecommendationView.swift` | `RecommendedCourseCard` |
| 加入課表 | `app/ViewModels/ScheduleVM.swift` | `ScheduleVM.addCourse()` |

### 設定
| 流程步驟 | 畫面/檔案 | ViewModel |
|---------|----------|-----------|
| 設定頁面 | `app/Views/MainTabView.swift` | `UtilitiesView` |
| 個人資料 | `app/Views/UserProfileView.swift` | `UserProfileManager` |
| 主題設定 | `app/Views/MainTabView.swift` | `ThemeManager` |

---

## 每個流程的狀態：Loading / Success / Error

### 匯入課表流程狀態

| 狀態 | 觸發條件 | UI 顯示 | 對應程式碼 |
|------|---------|--------|-----------|
| **Loading** | `fileImporter` 選擇檔案後 | `ScheduleVM.isImporting = true` | `app/ViewModels/ScheduleVM.swift:19` |
| **Success** | CSV 解析成功，課程已加入 | 顯示成功訊息，更新課表 | `ScheduleVM.addCourse()` |
| **Error** | CSV 格式錯誤或解析失敗 | `ScheduleVM.importWarnings` 顯示警告 | `CSVImporter.parseCourses()` |

### 看課表流程狀態

| 狀態 | 觸發條件 | UI 顯示 | 對應程式碼 |
|------|---------|--------|-----------|
| **Loading** | App 啟動時載入儲存的課表 | `ScheduleVM.loadCourses()` | `app/ViewModels/ScheduleVM.swift:338` |
| **Success** | 課表載入成功 | 顯示課程網格 | `ScheduleVM.courses` |
| **Error** | 儲存資料損壞或格式錯誤 | 顯示空課表，記錄錯誤 | `ScheduleVM.loadCourses()` catch |

### 查地圖流程狀態

| 狀態 | 觸發條件 | UI 顯示 | 對應程式碼 |
|------|---------|--------|-----------|
| **Loading** | `BuildingStore.load()` 執行中 | `BuildingStore.isLoading = true` | `app/Data/BuildingStore.swift:14` |
| **Success** | JSON 載入成功 | 顯示建築物列表/地圖標記 | `BuildingStore.all` |
| **Error** | JSON 檔案不存在或格式錯誤 | `BuildingStore.errorMessage`，使用範例資料 | `app/Data/BuildingStore.swift:39` |

### 空堂排課流程狀態

| 狀態 | 觸發條件 | UI 顯示 | 對應程式碼 |
|------|---------|--------|-----------|
| **Loading** | `CourseDataStore.loadCourses()` 執行中 | `CourseDataStore.isLoading = true` | `app/Data/CourseDataStore.swift:16` |
| **Success** | 課程資料載入成功，篩選完成 | 顯示推薦課程列表 | `SmartCourseRecommendationView.filteredCourses` |
| **Error** | CSV 檔案載入失敗 | `CourseDataStore.errorMessage`，顯示空列表 | `app/Data/CourseDataStore.swift:53` |

### WebView 開啟流程狀態

| 狀態 | 觸發條件 | UI 顯示 | 對應程式碼 |
|------|---------|--------|-----------|
| **Loading** | `SFSafariViewController` 載入中 | Safari 內建載入指示器 | `app/Views/SimpleWebView.swift:21` |
| **Success** | 網頁載入成功 | 顯示網頁內容 | `SFSafariViewController` |
| **Error** | 網路連線失敗或 URL 無效 | Safari 內建錯誤頁面 | `app/Views/SimpleWebView.swift:56` |

### 導航開啟流程狀態

| 狀態 | 觸發條件 | UI 顯示 | 對應程式碼 |
|------|---------|--------|-----------|
| **Success (App)** | Google Maps App 已安裝 | 開啟 Google Maps App | `app/Utils/CampusUtils.swift:23` |
| **Success (Web)** | Google Maps App 未安裝 | 開啟 Web 版 Google Maps | `app/Utils/CampusUtils.swift:30` |
| **Error** | URL 建立失敗 | `onError` callback 顯示錯誤訊息 | `app/Utils/CampusUtils.swift:31` |

---

## 特殊流程說明

### 從課表跳轉到地圖
```
SchedulePlannerView
    ↓
[點擊教室代號] (例如 "U館 204")
    ↓
NotificationCenter.post(
    name: .navigateToCampusMap,
    userInfo: ["buildingCode": "U"]
)
    ↓
MainTabView.onReceive()
    ↓
selectedTab = 3 (切換到校園地圖 Tab)
    ↓
NotificationCenter.post(
    name: "SearchBuildingInCampusMap",
    userInfo: ["buildingCode": "U"]
)
    ↓
CampusSearchView.onReceive()
    ↓
自動設定 searchText = "U"
    ↓
顯示搜尋結果
```

**對應檔案**：
- `app/Views/MainTabView.swift:56` - `onReceive(.navigateToCampusMap)`
- `app/Views/CampusSearchView.swift` - 接收搜尋通知

### 課表匯出流程
```
SchedulePlannerView
    ↓
[課表匯出] → ScheduleExportView
    ↓
[選擇格式] → CSV / iCal / 圖片
    ↓
ScheduleExporter.exportToCSV() / exportToiCal() / exportToImage()
    ↓
ShareSheet (UIActivityViewController)
    ↓
[選擇分享方式] → AirDrop / 儲存到檔案 / 其他 App
```

**對應檔案**：
- `app/Views/MainTabView.swift` - `ScheduleExportView`
- `app/Utils/ScheduleExporter.swift` - 匯出邏輯
- `app/Utils/ShareSheet.swift` - 分享功能

---

*最後更新：2025-01-23*



