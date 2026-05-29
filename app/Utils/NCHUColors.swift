//
//  NCHUColors.swift
//  NCHUHelper
//
//  Created on 2024-01-01.
//

import SwiftUI

/// NCHU Color Theme based on the university logo
struct NCHUColors {
    /// Primary gold color from NCHU logo
    static let primary = Color(red: 0.7, green: 0.6, blue: 0.3)
    
    /// Light gold for backgrounds
    static let primaryLight = Color(red: 0.7, green: 0.6, blue: 0.3).opacity(0.1)
    
    /// Medium gold for secondary elements
    static let primaryMedium = Color(red: 0.7, green: 0.6, blue: 0.3).opacity(0.6)
    
    /// Dark gold for text or emphasis
    static let primaryDark = Color(red: 0.6, green: 0.5, blue: 0.2)
    
    /// Gradient colors for special effects
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.8, green: 0.7, blue: 0.4),
            Color(red: 0.6, green: 0.5, blue: 0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Semantic Colors
    
    /// Success color (green)
    static let success = Color.green
    
    /// Warning color (orange) 
    static let warning = Color.orange
    
    /// Error color (red)
    static let error = Color.red
    
    /// Info color (blue)
    static let info = Color.blue
    
    // MARK: - Course Type Colors
    
    /// Course type color mapping
    static func courseTypeColor(for type: Course.RequiredType, theme: ThemeManager) -> Color {
        switch type {
        case .必修:
            return theme.requiredCourseColor.color
        case .選修:
            return theme.electiveCourseColor.color
        case .通識:
            return theme.generalEducationColor.color
        }
    }
}

/// Extension for easy access to NCHU colors
extension Color {
    static let nchuGold = NCHUColors.primary
    static let nchuGoldLight = NCHUColors.primaryLight
    static let nchuGoldMedium = NCHUColors.primaryMedium
    static let nchuGoldDark = NCHUColors.primaryDark
}
