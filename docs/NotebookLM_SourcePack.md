# NCHUHelper（初興）專案知識包

## 作品一句話定位

**中興大學學生專屬的課表管理與校園導航 App，整合選課規劃、空堂排課、校園地圖與校務系統。**

---

## 使用情境與痛點

### 痛點 1：選課規劃困難
- **問題**：學生需要手動比對多個課程的時間，容易發生衝堂
- **解決**：App 自動偵測衝堂，並提供空堂時間推薦通識課程

### 痛點 2：校園導航不便
- **問題**：新生或訪客不熟悉校園建築位置，找不到上課教室
- **解決**：整合 MapKit 地圖，提供 64+ 個建築物座標，支援 Apple Maps / Google Maps 導航

### 痛點 3：校務系統分散
- **問題**：選課、圖書館、行事曆等系統分散在不同網站，需要多次切換
- **解決**：整合常用校務網站（選課系統、圖書館、行事曆），一鍵開啟

---

## 功能總覽

### 1. 課表管理
- **手動新增/編輯課程**：點擊時間格或列表新增
- **CSV 匯入**：支援從選課系統匯出 CSV 檔匯入
- **衝堂偵測**：自動標示衝突課程（紅色標識）
- **空檔計算**：計算每週空檔時間，可設定最小連續節數
- **課表匯出**：支援 CSV、iCal、圖片格式（可當桌布）

### 2. 空堂排課（智慧推薦）
- **空堂時間選擇**：選擇星期與節次
- **通識課程篩選**：自動篩選符合空堂時間的通識課程
- **課程詳情查看**：支援查看課程大綱（需選課號碼）
- **一鍵加入課表**：直接將推薦課程加入個人課表

### 3. 校園地圖
- **建築物搜尋**：支援代號、名稱、別名搜尋（64+ 建築物）
- **地圖標記**：MapKit 顯示所有建築物位置
- **導航功能**：支援 Apple Maps / Google Maps 導航
- **點擊跳轉**：從課表點擊教室可直接跳轉到地圖搜尋

### 4. 整合校務網站
- **選課系統**：選課時程查詢
- **圖書館**：自學空間預約、數位出入管系統、圖書館官網
- **行事曆**：114 學年度行事曆 PDF 查看
- **WebView 整合**：使用 SFSafariViewController 安全開啟網頁

### 5. 其他功能
- **特約醫療院所**：顯示中興大學特約醫療優惠資訊，支援地圖查看
- **個人資料**：頭像選擇、系所年級設定
- **主題設定**：深色模式、主題色彩自訂

---

## 系統架構

### 三層架構（Presentation / Domain / Data）

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Views: SwiftUI)                       │
│  - MainTabView                          │
│  - SchedulePlannerView                 │
│  - CampusMapView                        │
│  - SmartCourseRecommendationView        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Domain Layer                     │
│  (ViewModels: MVVM)                      │
│  - ScheduleVM                            │
│  - CourseRecommendationEngine            │
│  - ThemeManager                           │
│  - AvatarManager                          │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Data Layer                       │
│  (Stores / Utils)                        │
│  - CourseDataStore                       │
│  - BuildingStore                         │
│  - MedicalDiscountStore                  │
│  - CSVImporter                           │
│  - ScheduleExporter                      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Resources                       │
│  - CSV 課程資料檔                        │
│  - Buildings.json                       │
│  - UserDefaults (本地儲存)               │
└─────────────────────────────────────────┘
```

### 主要資料流

#### 課程資料流
```
CSV 檔案 (Resources/)
    ↓
CourseDataStore.loadCourses()
    ↓
parseCourseFromCSVLine() → Course 模型
    ↓
CourseDataStore.allCourses (Published)
    ↓
SmartCourseRecommendationView / CoursePickerView
    ↓
ScheduleVM.addCourse()
    ↓
UserDefaults.standard (持久化)
```

#### 建築物資料流
```
Buildings.json (Resources/)
    ↓
BuildingStore.load()
    ↓
JSONDecoder → [Building]
    ↓
BuildingStore.all (Published)
    ↓
CampusMapView / CampusSearchView
    ↓
MapKit Annotation 顯示
```

#### 課表資料流
```
UserDefaults (本地儲存)
    ↓
ScheduleVM.loadCourses()
    ↓
ScheduleVM.courses (Published)
    ↓
SchedulePlannerView (TimetableGridView)
    ↓
衝突偵測 / 空檔計算
    ↓
UserDefaults.saveCourses() (自動儲存)
```

---

## 核心模組與責任

| 模組/類別名 | 用途 | 關聯檔案路徑 |
|------------|------|------------|
| **ScheduleVM** | 課表管理、衝堂偵測、空檔計算 | `app/ViewModels/ScheduleVM.swift` |
| **CourseDataStore** | 課程資料載入與快取（單例） | `app/Data/CourseDataStore.swift` |
| **BuildingStore** | 建築物資料載入與搜尋 | `app/Data/BuildingStore.swift` |
| **CSVImporter** | CSV 檔案解析工具 | `app/Utils/CSVImporter.swift` |
| **CourseRecommendationEngine** | 通識課程推薦引擎 | `app/ViewModels/CourseRecommendationEngine.swift` |
| **ScheduleExporter** | 課表匯出（CSV/iCal/圖片） | `app/Utils/ScheduleExporter.swift` |
| **ThemeManager** | 主題管理（深色模式、色彩） | `app/ViewModels/ThemeManager.swift` |
| **CampusUtils** | 校園功能工具（地圖導航） | `app/Utils/CampusUtils.swift` |
| **SimpleWebView** | WebView 整合（SFSafariViewController） | `app/Views/SimpleWebView.swift` |
| **Course** | 課程資料模型 | `app/Models/Course.swift` |
| **Building** | 建築物資料模型 | `app/Models/Building.swift` |

---

## 關鍵程式邏輯

### 1. 衝堂偵測演算法

**問題/需求**：偵測課程時間衝突，支援多時段課程

**做法**：
- 遍歷所有課程組合（O(n²)）
- 檢查每個課程的所有 `CourseSchedule` 時段
- 若兩課程有相同星期且節次重疊，標記為衝突

**影響範圍**：
- `SchedulePlannerView`：顯示紅色標識
- `ScheduleVM.conflicts()`：回傳衝突對
- `ScheduleVM.conflictedCourseIDs()`：回傳衝突課程 ID 集合

**對應檔案與關鍵函式**：
- `app/ViewModels/ScheduleVM.swift`
- `func conflicts(in courses: [Course]) -> [(Course, Course)]`

**關鍵程式片段**：
```swift
// 檢查所有時段組合是否有衝突
for schedule1 in course1.schedules {
    for schedule2 in course2.schedules {
        if schedule1.dayOfWeek == schedule2.dayOfWeek {
            let periods1 = Set(schedule1.periods)
            let periods2 = Set(schedule2.periods)
            if !periods1.isDisjoint(with: periods2) {
                hasConflict = true
                break outerLoop
            }
        }
    }
}
```

---

### 2. 空檔計算演算法

**問題/需求**：計算指定日期的連續空檔時間，過濾小於最小長度的空檔

**做法**：
1. 收集該日所有已佔用的節次
2. 計算未佔用的節次（1-14 節）
3. 將連續節次分組為範圍（ClosedRange<Int>）
4. 過濾長度 < minLength 的空檔

**影響範圍**：
- `SchedulePlannerView`：顯示空檔摘要
- `SmartCourseRecommendationView`：根據空檔篩選課程
- `FreeSlotFormatter`：格式化空檔顯示

**對應檔案與關鍵函式**：
- `app/ViewModels/ScheduleVM.swift`
- `func freeSlots(courses:on:totalPeriods:minLength:) -> [ClosedRange<Int>]`

**關鍵程式片段**：
```swift
// 收集所有已佔用節次
let occupiedPeriods = Set(
    courses.flatMap { course in
        course.schedules
            .filter { $0.dayOfWeek == day }
            .flatMap { $0.periods }
    }
)

// 找出空檔並分組為連續範圍
let freePeriods = totalPeriods.filter { !occupiedPeriods.contains($0) }
// ... 分組邏輯 ...
```

---

### 3. CSV 課程資料解析

**問題/需求**：解析中興大學選課系統匯出的 CSV 格式，支援多時段課程

**做法**：
- 支援兩種格式：新格式（schedule 欄位）與舊格式（dayOfWeek + periods）
- `schedule` 格式：`"1234"` = 週一 2,3,4 節；`"234,35"` = 週二 3,4 節 + 週三 5 節
- 解析時處理引號、逗號、換行等特殊字元
- 錯誤處理：跳過無效行，收集警告訊息

**影響範圍**：
- `CourseDataStore`：載入所有課程資料
- `SchedulePlannerView`：CSV 匯入功能
- `CoursePickerView`：顯示可選課程

**對應檔案與關鍵函式**：
- `app/Data/CourseDataStore.swift`
- `private func parseCourseFromCSVLine(_ line: String) throws -> Course`
- `private func parseSchedules(_ scheduleString: String) -> [CourseSchedule]`

**關鍵程式片段**：
```swift
// 解析時段字串 "1234" → 週一 2,3,4 節
let digits = firstSlot.compactMap { char -> Int? in
    if let digit = Int(String(char)), digit >= 0 && digit <= 9 {
        return digit
    }
    return nil
}
let dayOfWeek = digits[0]
let periods = Array(digits.dropFirst())
```

---

### 4. 空堂排課篩選邏輯

**問題/需求**：根據使用者選擇的空堂時間，篩選出符合條件的通識課程

**做法**：
1. 使用者選擇星期與節次（可多選）
2. 從 `CourseDataStore.allCourses` 篩選通識課程
3. 檢查課程時段是否完全落在選擇的空堂時間內
4. 排除與現有課表衝突的課程
5. 排序：優先顯示有課程大綱的課程

**影響範圍**：
- `SmartCourseRecommendationView`：顯示推薦課程列表
- `CourseRecommendationEngine`：推薦引擎邏輯

**對應檔案與關鍵函式**：
- `app/Views/SmartCourseRecommendationView.swift`
- `private func filterCourses()`

**關鍵程式片段**：
```swift
// 篩選符合空堂時間的課程
filteredCourses = allCourses.filter { course in
    // 只顯示通識課程
    guard course.requiredType == .通識 else { return false }
    
    // 檢查所有時段是否都在選擇的空堂時間內
    return course.schedules.allSatisfy { schedule in
        selectedDay == schedule.dayOfWeek &&
        Set(schedule.periods).isSubset(of: selectedPeriods)
    }
}
```

---

### 5. WebView 預熱機制

**問題/需求**：解決首次開啟 WebView 時出現白畫面的問題

**做法**：
- App 啟動時預先建立 `WKWebView` 並載入興大首頁
- 觸發網路權限與 SSL 憑證預載
- 2 秒後釋放預熱 WebView
- 使用 `sheet(item:)` 確保 URL 在 sheet 顯示時已正確設定

**影響範圍**：
- `appApp.swift`：App 啟動時預熱
- `MainTabView`：所有 WebView 開啟功能
- `SimpleWebView`：WebView 實作

**對應檔案與關鍵函式**：
- `app/appApp.swift`
- `private func preWarmWebView()`

**關鍵程式片段**：
```swift
// 預熱 WebView 以解決首次載入問題
let preWarmWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
if let url = URL(string: "https://www.nchu.edu.tw") {
    preWarmWebView.load(URLRequest(url: url))
}
```

---

## 例外處理與穩定性設計

### 1. 資料載入失敗處理
- **CSV 解析錯誤**：跳過無效行，收集警告訊息，不中斷載入流程
- **JSON 載入失敗**：使用範例資料（`Building.sampleBuildings`、`MedicalDiscount.sampleDiscounts`）
- **檔案不存在**：顯示錯誤訊息，提供降級方案

**對應檔案**：
- `app/Data/CourseDataStore.swift`：`loadCoursesFromCSV()` 錯誤處理
- `app/Data/BuildingStore.swift`：`loadBuildingsData()` fallback

### 2. 網路連線處理
- **WebView 載入失敗**：顯示錯誤訊息，允許重試
- **地圖導航失敗**：降級到 Web 版 Google Maps

**對應檔案**：
- `app/Views/SimpleWebView.swift`：`SafariWebView` 錯誤處理
- `app/Utils/CampusUtils.swift`：`openGoogleMap()` fallback

### 3. 資料格式變動
- **CSV 格式變動**：支援新舊兩種格式，自動偵測
- **JSON 格式變動**：使用 `Codable` 協議，欄位缺失時使用預設值

**對應檔案**：
- `app/Utils/CSVImporter.swift`：格式偵測邏輯
- `app/Models/Course.swift`：`Codable` 實作

### 4. 離線快取
- **課程資料**：`UserDefaults` 持久化，App 重啟後自動載入
- **主題設定**：`UserDefaults` 儲存深色模式、主題色彩
- **頭像選擇**：`UserDefaults` 儲存選擇的頭像樣式

**對應檔案**：
- `app/ViewModels/ScheduleVM.swift`：`saveCourses()` / `loadCourses()`
- `app/ViewModels/ThemeManager.swift`：`loadPreferences()`
- `app/ViewModels/AvatarManager.swift`：`saveSelectedAvatar()`

### 5. 載入狀態管理
- **Loading 狀態**：`@Published var isLoading` 顯示載入指示器
- **Error 狀態**：`@Published var errorMessage` 顯示錯誤訊息
- **空狀態**：顯示「沒有資料」提示

**對應檔案**：
- `app/Data/CourseDataStore.swift`：`isLoading` / `errorMessage`
- `app/Data/BuildingStore.swift`：`isLoading` / `errorMessage`

---

## Demo 講稿（60-90 秒）

### 開場（10 秒）
「大家好，我是 [姓名]。今天要介紹的是『初興』App，這是專為中興大學學生設計的課表管理與校園導航工具。」

### 點功能（30 秒）
「首先，我們來看課表管理功能。使用者可以手動新增課程，或從選課系統匯入 CSV 檔。App 會自動偵測衝堂，並用紅色標示衝突的課程。接著，我們可以查看每週的空檔時間，並使用『空堂排課』功能，選擇空堂時間後，App 會自動篩選出符合條件的通識課程，一鍵加入課表。」

### 亮點（30 秒）
「接下來是校園地圖功能。App 整合了 64 個建築物的座標，使用者可以搜尋建築物代號或名稱，點擊後直接開啟 Apple Maps 或 Google Maps 導航。此外，App 也整合了常用校務網站，包括選課系統、圖書館、行事曆等，一鍵開啟，不需要切換多個 App。」

### 收尾（10-20 秒）
「最後，App 支援課表匯出為 CSV、iCal 或圖片格式，可以當作手機桌布。所有資料都儲存在本地，保護隱私。謝謝大家！」

---

## 可被評審問的問題 & 回答草稿

### Q1：為什麼選擇 SwiftUI 而不是 UIKit？
**A**：SwiftUI 提供宣告式 UI，程式碼更簡潔，且與 iOS 17+ 原生整合良好。MVVM 架構讓 ViewModel 與 View 分離，易於測試與維護。

### Q2：如何處理大量課程資料的效能問題？
**A**：使用 `CourseDataStore` 單例模式，App 啟動時一次性載入所有課程資料到記憶體。搜尋與篩選使用 `filter` 與 `Set` 操作，時間複雜度 O(n)。衝堂偵測雖然是 O(n²)，但實際課程數量通常在 100-300 門，效能足夠。

### Q3：CSV 匯入如何處理格式不一致的問題？
**A**：實作了格式自動偵測機制，支援新舊兩種格式。解析時使用 `parseCSVLine()` 處理引號與逗號，錯誤行會跳過並收集警告訊息，不中斷整體匯入流程。

### Q4：地圖資料如何取得？如何確保座標準確？
**A**：建築物座標資料儲存在 `Resources/Buildings.json`，目前包含 64 個建築物的座標。座標是根據中興大學校園地圖手動整理，未來可整合官方 GIS 資料或讓使用者回報錯誤。

### Q5：WebView 整合如何確保安全性？
**A**：優先使用 `SFSafariViewController`，這是 Apple 推薦的安全方式，自動處理 Cookie 與憑證。只有在需要深度整合時才使用 `WKWebView`，並實作了預熱機制避免首次載入問題。

### Q6：App 如何處理離線使用？
**A**：所有課程資料、建築物資料、個人課表都儲存在本地（UserDefaults 與 Bundle Resources），不需要網路連線即可使用。只有開啟校務網站時才需要網路。

### Q7：如何擴展到其他學校？
**A**：架構設計上，`CourseDataStore` 與 `BuildingStore` 都是資料驅動的，只需要替換 CSV 與 JSON 檔案即可。未來可考慮加入「學校選擇」功能，動態載入不同學校的資料。

### Q8：為什麼不使用後端 API？
**A**：為了保護使用者隱私與降低開發成本，所有資料都儲存在本地。課程資料從選課系統匯出 CSV 即可使用，不需要額外的後端服務。

---

## 尚未在專案找到但簡報可能需要補的資訊清單

### 1. 資料來源
- [ ] 課程 CSV 檔的取得方式（是否從選課系統匯出？）
- [ ] 建築物座標的來源（是否從官方 GIS 取得？）
- [ ] 醫療優惠資料的更新頻率

### 2. 使用者測試
- [ ] 是否有進行使用者測試？
- [ ] 使用者回饋的主要痛點
- [ ] App 下載量或使用人數（若有）

### 3. 技術細節
- [ ] App 大小（Bundle Size）
- [ ] 啟動時間（Cold Start）
- [ ] 記憶體使用量
- [ ] 是否有使用 Analytics（Firebase / Mixpanel 等）

### 4. 未來規劃
- [ ] 是否計劃加入推播通知（選課提醒等）
- [ ] 是否計劃加入社群功能（課程評價等）
- [ ] 是否計劃支援 Android 版本

### 5. 競品分析
- [ ] 與其他校園 App 的差異化優勢
- [ ] 是否有參考其他學校的類似 App

---

*最後更新：2025-01-23*



