# NCHUHelper 開發進度追蹤

## 專案概述
- **專案名稱**: 初興
- **目標**: 選課空堂規劃 + 校園大樓導航
- **平台**: iOS 17+, Xcode 15+, Swift 5.9, SwiftUI, MapKit
- **架構**: SwiftUI + MVVM + Utils (無第三方依賴)

## 開發里程碑

### M1: 初始化專案結構與 App 入口 ✅ 
- [x] 創建目錄結構 (Models, ViewModels, Views, Utils, Data, Resources)
- [x] 重構 appApp.swift (移除 SwiftData，改名 NCHUHelperApp)
- [x] 建立 HomeView 與雙卡片導航
- [x] 刪除範本文件 (Item.swift, ContentView.swift)

### M2: 實作 Models 與 ViewModels ✅
- [x] 創建 Course.swift 模型 (支援衝堂檢測與時間計算)
- [x] 創建 Building.swift 模型 (支援地圖導航)
- [x] 創建 ScheduleVM.swift 完整實作
- [x] 創建 FreeSlotFormatter.swift (空檔時間格式化)

### M3: 課表網格編輯器與手動排課功能 ✅
- [x] 實作 TimetableGridView (14x5 課表網格)
- [x] 實作 CourseFormView (新增/編輯課程表單)
- [x] 實作 TimeSlotCell (時間槽互動)
- [x] 課程拖放與即時編輯功能
- [x] 課程類型標識與顏色編碼

### M4: 衝堂偵測與空檔計算功能 ✅
- [x] 在 ScheduleVM 中實作 conflicts(...) 與 conflictedCourseIDs(...)
- [x] 在課表網格中即時標示衝堂課程 (紅色標識)
- [x] 實作 freeSlots(...) 與每週空檔計算
- [x] 底部顯示空檔統計與摘要

### M5: 校園地圖搜尋與導航功能 ✅
- [x] 創建 BuildingStore 載入 Resources/Buildings.json
- [x] 實作 CampusSearchView 搜尋功能 (code/name/aliases)
- [x] 添加 Apple Maps / Google Maps 導航按鈕
- [x] 更新 Info.plist (NSLocationWhenInUseUsageDescription, LSApplicationQueriesSchemes)
- [x] 創建示例建築資料 (20+ 校園建築)

### M6: 測試與配置 ✅ (基礎完成)
- [x] 單元測試 (ScheduleVMTests: 衝堂偵測、空檔計算、課程管理)
- [x] Info.plist 權限配置
- [x] 示例資料建立 (Course.sampleCourses, Building.sampleBuildings)
- [ ] UI 細節優化與 Accessibility (待後續)

## 目錄結構
```
/Models              # Course.swift, Building.swift
/ViewModels          # ScheduleVM.swift
/Views               # HomeView.swift, SchedulePlannerView.swift, CampusSearchView.swift  
/Utils               # CSVImporter.swift, FreeSlotFormatter.swift
/Data                # BuildingStore.swift, CoursesStore.swift
/Resources           # Buildings.json, sample_courses.csv
/Assets.xcassets     # 圖片與顏色
/PreviewContent      # Mock 資料 (預覽用)
```

## 當前狀態
正在進行 M1 階段，已完成目錄結構創建，接下來重構 App 入口點。

## 測試方式
- 在 iOS 17 模擬器中測試
- 驗證 SwiftUI 預覽正常運作
- 確保無編譯警告

---
*最後更新: $(date)*
