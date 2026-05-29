//
//  ShareSheet.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/1/23.
//

import SwiftUI
import UIKit

/// 共享的分享表單元件
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

