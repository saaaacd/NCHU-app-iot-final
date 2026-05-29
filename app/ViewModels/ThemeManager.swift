//
//  ThemeManager.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import SwiftUI
import Combine

/// Manages the app's theme settings including dark mode and accent colors
@MainActor
final class ThemeManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether dark mode is enabled
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    /// Current accent color
    @Published var accent: AccentColor = .nchuGold {
        didSet {
            UserDefaults.standard.set(accent.rawValue, forKey: "accentColor")
        }
    }
    
    /// Course type colors
    @Published var requiredCourseColor: CourseTypeColor = .nchuGold {
        didSet {
            UserDefaults.standard.set(requiredCourseColor.rawValue, forKey: "requiredCourseColor")
        }
    }
    
    @Published var electiveCourseColor: CourseTypeColor = .green {
        didSet {
            UserDefaults.standard.set(electiveCourseColor.rawValue, forKey: "electiveCourseColor")
        }
    }
    
    @Published var generalEducationColor: CourseTypeColor = .purple {
        didSet {
            UserDefaults.standard.set(generalEducationColor.rawValue, forKey: "generalEducationColor")
        }
    }
    
    // MARK: - Accent Color Options
    
    enum AccentColor: String, CaseIterable {
        case nchuGold = "nchuGold"
        case blue = "blue"
        case green = "green"
        case purple = "purple"
        case red = "red"
        
        var color: Color {
            switch self {
            case .nchuGold:
                return NCHUColors.primary
            case .blue:
                return .blue
            case .green:
                return .green
            case .purple:
                return .purple
            case .red:
                return .red
            }
        }
        
        var displayName: String {
            switch self {
            case .nchuGold:
                return "中興金"
            case .blue:
                return "藍色"
            case .green:
                return "綠色"
            case .purple:
                return "紫色"
            case .red:
                return "紅色"
            }
        }
    }
    
    // MARK: - Course Type Color Options
    
    enum CourseTypeColor: String, CaseIterable {
        case nchuGold = "nchuGold"
        case blue = "blue"
        case green = "green"
        case purple = "purple"
        case red = "red"
        case orange = "orange"
        case teal = "teal"
        case pink = "pink"
        case indigo = "indigo"
        case brown = "brown"
        
        var color: Color {
            switch self {
            case .nchuGold:
                return NCHUColors.primary
            case .blue:
                return .blue
            case .green:
                return .green
            case .purple:
                return .purple
            case .red:
                return .red
            case .orange:
                return .orange
            case .teal:
                return .teal
            case .pink:
                return .pink
            case .indigo:
                return .indigo
            case .brown:
                return .brown
            }
        }
        
        var displayName: String {
            switch self {
            case .nchuGold:
                return "中興金"
            case .blue:
                return "藍色"
            case .green:
                return "綠色"
            case .purple:
                return "紫色"
            case .red:
                return "紅色"
            case .orange:
                return "橘色"
            case .teal:
                return "青藍色"
            case .pink:
                return "粉紅色"
            case .indigo:
                return "靛藍色"
            case .brown:
                return "棕色"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved preferences
        loadPreferences()
    }
    
    // MARK: - Private Methods
    
    private func loadPreferences() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        if let savedAccentColor = UserDefaults.standard.string(forKey: "accentColor"),
           let accentColor = AccentColor(rawValue: savedAccentColor) {
            accent = accentColor
        }
        
        // Load course type colors
        if let savedRequiredColor = UserDefaults.standard.string(forKey: "requiredCourseColor"),
           let requiredColor = CourseTypeColor(rawValue: savedRequiredColor) {
            requiredCourseColor = requiredColor
        }
        
        if let savedElectiveColor = UserDefaults.standard.string(forKey: "electiveCourseColor"),
           let electiveColor = CourseTypeColor(rawValue: savedElectiveColor) {
            electiveCourseColor = electiveColor
        }
        
        if let savedGeneralColor = UserDefaults.standard.string(forKey: "generalEducationColor"),
           let generalColor = CourseTypeColor(rawValue: savedGeneralColor) {
            generalEducationColor = generalColor
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggle between light and dark mode
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
    
    /// Update the accent color
    func updateAccentColor(_ newAccent: AccentColor) {
        accent = newAccent
    }
    
    /// Reset theme to defaults
    func resetToDefaults() {
        isDarkMode = false
        accent = .nchuGold
    }
}

// MARK: - Theme Helper Extension

extension ThemeManager {
    /// Get primary text color based on current theme
    var primaryTextColor: Color {
        isDarkMode ? .white : .black
    }
    
    /// Get secondary text color based on current theme
    var secondaryTextColor: Color {
        isDarkMode ? .gray : .secondary
    }
    
    /// Get background color based on current theme
    var backgroundColor: Color {
        isDarkMode ? Color(.systemBackground) : .white
    }
    
    /// Get secondary background color based on current theme
    var secondaryBackgroundColor: Color {
        isDarkMode ? Color(.secondarySystemBackground) : Color(.systemGray6)
    }
}
