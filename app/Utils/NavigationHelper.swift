//
//  NavigationHelper.swift
//  初興 (NCHUHelper)
//
//  Created by AI Assistant on 2025/10/13.
//

import SwiftUI

/// Helper class for navigation between different views in the app
struct NavigationHelper {
    
    /// Navigate to campus map and search for a specific building
    static func navigateToCampusMap(buildingCode: String) {
        // This is a placeholder implementation
        // In a real app, you would need to implement proper navigation
        // For now, we'll use notification to communicate with the main tab view
        
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToCampusMap"),
            object: nil,
            userInfo: ["buildingCode": buildingCode]
        )
    }
}

/// Notification names for navigation
extension NSNotification.Name {
    static let navigateToCampusMap = NSNotification.Name("NavigateToCampusMap")
}

