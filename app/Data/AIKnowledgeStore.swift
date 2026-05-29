import Foundation

class AIKnowledgeStore {
    static let shared = AIKnowledgeStore()
    private var knowledgeList: [AIKnowledge] = []
    
    private init() {
        loadKnowledge()
    }
    
    private func loadKnowledge() {
        guard let url = Bundle.main.url(forResource: "AI_KnowledgeBase", withExtension: "json") else {
            print("找不到 AI_KnowledgeBase.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            knowledgeList = try JSONDecoder().decode([AIKnowledge].self, from: data)
            print("成功載入 \(knowledgeList.count) 筆 AI 內部知識庫資料")
        } catch {
            print("讀取 AI_KnowledgeBase.json 失敗：\(error)")
        }
    }
    
    // 搜尋內部資料庫中是否有符合使用者問題的關鍵字
    func searchRelevantContext(for query: String) -> String? {
        let lowercasedQuery = query.lowercased()
        var relevantContents: [String] = []
        
        for item in knowledgeList {
            // 只要使用者的提問包含知識庫中的任何一個關鍵字，就把這筆知識納入
            for keyword in item.keywords {
                if lowercasedQuery.contains(keyword.lowercased()) {
                    relevantContents.append(item.content)
                    break // 避免同一個 item 因為多個關鍵字符合而重複加入
                }
            }
        }
        
        if relevantContents.isEmpty {
            return nil
        } else {
            return relevantContents.joined(separator: "\n\n")
        }
    }
}
