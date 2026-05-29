import Foundation
import Combine

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    
    // 常見問題清單（預覽按鈕使用）
    @Published var suggestedQuestions: [String] = []
    
    // 30 個常見問題池
    private let allCommonQuestions: [String] = [
        "戴淯琮教授教什麼課？",
        "圖書館開放到幾點？",
        "綜合教學大樓在哪裡？",
        "初興 App 有什麼功能？",
        "王秀郎教授有開什麼課？",
        "張軒彬教授教什麼科目？",
        "陳奕中教授的課有哪些？",
        "體育館什麼時候開放？",
        "特約診所看病有打折嗎？",
        "怎麼在 App 裡看我的課表？",
        "學生活動中心在哪裡？",
        "通識課要修幾學分才能畢業？",
        "要怎麼請病假？",
        "請事假需要提早幾天申請？",
        "學校的學生餐廳在哪裡？",
        "保健中心的開放時間是？",
        "資訊科學大樓(計中)在哪裡？",
        "微積分是必修嗎？",
        "楊景明教授有教什麼課？",
        "這學期什麼時候期中考？",
        "可以在校園哪裡自習？",
        "圖書館自習室怎麼預約？",
        "必修課被當掉怎麼辦？",
        "學校有什麼獎學金可以申請？",
        "學生的機車要停在哪裡？",
        "行政大樓在哪裡？",
        "語言中心(A601)在哪棟大樓？",
        "怎麼用這個 App 找大樓？",
        "什麼是核心通識？",
        "體育課一學期可以選兩門嗎？"
    ]
    
    // 設定中轉 API 的 URL 與 API Key (請在這裡替換成你實際的 URL 和 Key)
    let proxyBaseURL = "https://tbnx.plus7.plus/v1/chat/completions"
    let apiKey = "sk-2Z4EqTRQv11LGxpQLRgCn2USl2xT8j7d60cYOug4jvluRS3z"
    
    init() {
        // 加入初始歡迎訊息
        messages.append(ChatMessage(content: "你好！我是初興 AI 助手，有什麼校園資訊、選課問題或是大樓位置想問我嗎？", isUser: false))
        
        // 每次進入時隨機挑選 4 個問題
        suggestedQuestions = Array(allCommonQuestions.shuffled().prefix(4))
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMsg = ChatMessage(content: text, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isTyping = true
        
        Task {
            await fetchAIResponse(for: text)
        }
    }
    
    // 供建議問題的快捷按鈕呼叫
    func sendSuggestedMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMsg = ChatMessage(content: trimmed, isUser: true)
        messages.append(userMsg)
        isTyping = true
        
        Task {
            await fetchAIResponse(for: trimmed)
        }
    }
    
    private func fetchAIResponse(for userText: String) async {
        var systemContent = "你是一個名叫「初興小幫手」的 AI 助手，專門解答台灣中興大學(NCHU)的校園資訊、選課問題、大樓位置等。你的語氣要友善、專業、簡潔。如果不清楚的事情請誠實告知。"
        
        // 1. 搜尋 AI_KnowledgeBase.json 內部資料庫
        if let localContext = AIKnowledgeStore.shared.searchRelevantContext(for: userText) {
            systemContent += "\n\n【請優先參考以下內部資料庫資訊來回答使用者問題】\n\(localContext)"
        }
        
        // 2. 搜尋大樓資料庫 (如果有問到特定大樓)
        var allBuildings = Building.sampleBuildings
        if let url = Bundle.main.url(forResource: "Buildings", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let parsed = try? JSONDecoder().decode([Building].self, from: data) {
            allBuildings = parsed
        }
        
        let matchedBuildings = allBuildings.filter { building in
            userText.contains(building.name) || building.aliases.contains(where: { userText.contains($0) })
        }
        if !matchedBuildings.isEmpty {
            let buildingInfo = matchedBuildings.map { "\($0.name)（代碼：\($0.code)）- 開放時間：\($0.openHours ?? "未提供")" }.joined(separator: "\n")
            systemContent += "\n\n【校園大樓內部資料庫】\n\(buildingInfo)"
        }
        
        // 3. 搜尋教授與課程資料 (如果問到特定教授)
        let allCourses = await CourseDataStore.shared.allCourses
        let matchedCourses = allCourses.filter { course in
            if let instructor = course.instructor, !instructor.isEmpty, userText.contains(instructor) {
                return true
            }
            return false
        }
        
        if !matchedCourses.isEmpty {
            // 取出前 10 筆避免 prompt 太長
            let courseInfo = matchedCourses.prefix(10).map { "教師：\($0.instructor ?? "")，開授課程：\($0.name) (\($0.dept))，學分：\($0.credits ?? 0)" }.joined(separator: "\n")
            systemContent += "\n\n【教授開課內部資料庫】\n\(courseInfo)"
            if matchedCourses.count > 10 {
                systemContent += "\n(還有更多課程未列出)"
            }
        }
        
        // 準備對話歷史
        var requestMessages: [[String: String]] = [
            ["role": "system", "content": systemContent]
        ]
        
        for msg in messages {
            requestMessages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini", // 根據測試，此中轉站支援 gpt-4o-mini
            "messages": requestMessages,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: proxyBaseURL) else {
            await MainActor.run {
                self.messages.append(ChatMessage(content: "API URL 設定錯誤。", isUser: false))
                self.isTyping = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.messages.append(ChatMessage(content: "網路連線異常，請稍後再試。", isUser: false))
                    self.isTyping = false
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    await MainActor.run {
                        self.messages.append(ChatMessage(content: content, isUser: false))
                        self.isTyping = false
                    }
                } else {
                    await MainActor.run {
                        self.messages.append(ChatMessage(content: "無法解析回傳資料格式。", isUser: false))
                        self.isTyping = false
                    }
                }
            } else {
                // 如果回傳非 200，嘗試印出錯誤訊息幫助除錯
                let errorMsg = String(data: data, encoding: .utf8) ?? "未知錯誤"
                print("API 錯誤 (\(httpResponse.statusCode)): \(errorMsg)")
                await MainActor.run {
                    self.messages.append(ChatMessage(content: "伺服器錯誤 (\(httpResponse.statusCode))，請檢查 API 設定。", isUser: false))
                    self.isTyping = false
                }
            }
        } catch {
            await MainActor.run {
                self.messages.append(ChatMessage(content: "發生錯誤：\(error.localizedDescription)", isUser: false))
                self.isTyping = false
            }
        }
    }
}
