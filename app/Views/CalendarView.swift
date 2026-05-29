//
//  CalendarView.swift
//  初興 (NCHUHelper)
//
//  Created by 劉李陽 on 2025/9/21.
//

import SwiftUI
import PDFKit
import UIKit

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                if let pdfURL = getPDFURL() {
                    PDFViewRepresentable(url: pdfURL)
                        .onAppear {
                            self.pdfURL = pdfURL
                        }
                } else {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("無法載入行事曆")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("114學年度行事曆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(theme.accent.color)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 分享按鈕
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(theme.accent.color)
                    }
                    .disabled(pdfURL == nil)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
    }
    
    private func getPDFURL() -> URL? {
        guard let path = Bundle.main.path(forResource: "114學年度行事曆", ofType: "pdf") else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
    
}

// PDF 檢視器
struct PDFViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // 不需要更新
    }
}

#Preview {
    CalendarView()
        .environmentObject(ThemeManager())
}
