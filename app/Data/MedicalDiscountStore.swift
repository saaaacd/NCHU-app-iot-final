import Foundation
import Combine

@MainActor
final class MedicalDiscountStore: ObservableObject {
    @Published var allDiscounts: [MedicalDiscount] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let fileName = "nchu_medical_discounts"
    
    init() {
        loadDiscounts()
    }
    
    func loadDiscounts() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let discounts = try await loadFromCSV()
                await MainActor.run {
                    self.allDiscounts = discounts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    // 如果載入失敗，使用範例資料
                    self.allDiscounts = MedicalDiscount.sampleDiscounts
                }
            }
        }
    }
    
    private func loadFromCSV() async throws -> [MedicalDiscount] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw MedicalDiscountError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw MedicalDiscountError.invalidEncoding
        }
        
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw MedicalDiscountError.emptyFile
        }
        
        // 跳過標題行
        let dataLines = Array(lines.dropFirst()).filter { !$0.isEmpty }
        var discounts: [MedicalDiscount] = []
        
        for (index, line) in dataLines.enumerated() {
            do {
                let discount = try parseCSVLine(line)
                discounts.append(discount)
            } catch {
                print("⚠️ 解析第 \(index + 2) 行時發生錯誤: \(error)")
                continue
            }
        }
        
        return discounts
    }
    
    
    private func parseCSVLine(_ line: String) throws -> MedicalDiscount {
        // 簡化的CSV解析，假設數據已經是正確格式
        let components = line.components(separatedBy: ",")
        
        // 如果分割後的組件數量不正確，嘗試更智能的解析
        if components.count < 8 {
            // 使用更robust的CSV解析
            let columns = parseCSVWithQuotes(line)
            guard columns.count >= 8 else {
                throw MedicalDiscountError.invalidFormat
            }
            
            return MedicalDiscount(
                category: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                hospitalName: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                eligiblePersons: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                specialtyMedicine: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                discountItems: columns[4].trimmingCharacters(in: .whitespacesAndNewlines),
                address: columns[5].trimmingCharacters(in: .whitespacesAndNewlines),
                phone: columns[6].trimmingCharacters(in: .whitespacesAndNewlines),
                googleMapsURL: columns[7].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else {
            // 簡單解析
            return MedicalDiscount(
                category: components[0].trimmingCharacters(in: .whitespacesAndNewlines),
                hospitalName: components[1].trimmingCharacters(in: .whitespacesAndNewlines),
                eligiblePersons: components[2].trimmingCharacters(in: .whitespacesAndNewlines),
                specialtyMedicine: components[3].trimmingCharacters(in: .whitespacesAndNewlines),
                discountItems: components[4].trimmingCharacters(in: .whitespacesAndNewlines),
                address: components[5].trimmingCharacters(in: .whitespacesAndNewlines),
                phone: components[6].trimmingCharacters(in: .whitespacesAndNewlines),
                googleMapsURL: components[7].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
    
    private func parseCSVWithQuotes(_ line: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // 添加最後一列
        columns.append(currentColumn)
        
        // 移除引號
        return columns.map { column in
            var cleanColumn = column
            if cleanColumn.hasPrefix("\"") && cleanColumn.hasSuffix("\"") {
                cleanColumn = String(cleanColumn.dropFirst().dropLast())
            }
            return cleanColumn
        }
    }
    
    // MARK: - 搜尋功能
    
    func searchDiscounts(keyword: String) -> [MedicalDiscount] {
        guard !keyword.isEmpty else {
            return allDiscounts
        }
        
        let lowercaseKeyword = keyword.lowercased()
        let filteredDiscounts = allDiscounts.filter { discount in
            discount.hospitalName.lowercased().contains(lowercaseKeyword) ||
            discount.category.lowercased().contains(lowercaseKeyword) ||
            discount.specialtyMedicine.lowercased().contains(lowercaseKeyword) ||
            discount.address.lowercased().contains(lowercaseKeyword)
        }
        
        // 按優先順序排序搜尋結果
        let priorityOrder = ["耳鼻喉科", "中醫", "眼科", "牙科", "綜合醫院"]
        
        return filteredDiscounts.sorted { discount1, discount2 in
            let index1 = priorityOrder.firstIndex(of: discount1.category) ?? priorityOrder.count
            let index2 = priorityOrder.firstIndex(of: discount2.category) ?? priorityOrder.count
            
            if index1 != index2 {
                return index1 < index2
            }
            
            // 如果是同一類別，按醫院名稱排序
            return discount1.hospitalName < discount2.hospitalName
        }
    }
    
    // MARK: - 分類功能
    
    func discountsByCategory() -> [String: [MedicalDiscount]] {
        Dictionary(grouping: allDiscounts) { $0.category }
    }
    
    var availableCategories: [String] {
        let allCategories = Array(Set(allDiscounts.map { $0.category }))
        let priorityOrder = ["耳鼻喉科", "中醫", "眼科", "牙科", "綜合醫院"]
        
        // 按優先順序排序，其他類別按字母順序放在後面
        let priorityCategories = priorityOrder.filter { allCategories.contains($0) }
        let otherCategories = allCategories.filter { !priorityOrder.contains($0) }.sorted()
        
        return priorityCategories + otherCategories
    }
    
    func getDiscounts(for category: String) -> [MedicalDiscount] {
        let filteredDiscounts = allDiscounts.filter { $0.category == category }
        return filteredDiscounts.sorted { $0.hospitalName < $1.hospitalName }
    }
}

// MARK: - Error Types

enum MedicalDiscountError: LocalizedError {
    case fileNotFound
    case invalidEncoding
    case emptyFile
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到醫療優惠資料檔案"
        case .invalidEncoding:
            return "檔案編碼格式不正確"
        case .emptyFile:
            return "資料檔案為空"
        case .invalidFormat:
            return "資料格式不正確"
        }
    }
}
