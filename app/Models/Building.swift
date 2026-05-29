//
//  Building.swift
//  NCHUHelper
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation
import CoreLocation

struct Building: Identifiable, Codable, Hashable {
    let id: UUID
    var code: String         // e.g., "工綜館"
    var name: String         // e.g., "工程綜合館"
    var aliases: [String]    // Alternative names for search
    var lat: Double          // Latitude
    var lng: Double          // Longitude  
    var openHours: String?   // Optional opening hours
    
    // Custom initializer with auto-generated UUID
    init(
        code: String,
        name: String,
        aliases: [String] = [],
        lat: Double,
        lng: Double,
        openHours: String? = nil
    ) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.aliases = aliases
        self.lat = lat
        self.lng = lng
        self.openHours = openHours
    }
    
    // MARK: - Computed Properties
    
    /// CLLocationCoordinate2D for MapKit integration
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    /// Display name combining code and name
    var displayName: String {
        if code == name {
            return code
        } else {
            return "\(code) (\(name))"
        }
    }
    
    /// All searchable terms (code, name, aliases)
    var searchableTerms: [String] {
        return [code, name] + aliases
    }
    
    // MARK: - Methods
    
    /// Check if building matches search keyword (case-insensitive)
    func matches(keyword: String) -> Bool {
        let lowercaseKeyword = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lowercaseKeyword.isEmpty else { return true }
        
        return searchableTerms.contains { term in
            term.lowercased().contains(lowercaseKeyword)
        }
    }
    
    /// Generate Apple Maps URL for navigation
    func appleMapURL() -> URL? {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "http://maps.apple.com/?ll=\(lat),\(lng)&q=\(encodedName)"
        return URL(string: urlString)
    }
    
    /// Generate Google Maps URL for navigation
    func googleMapURL() -> URL? {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "comgooglemaps://?q=\(lat),\(lng)(\(encodedName))"
        return URL(string: urlString)
    }
    
    /// Generate Google Maps web URL as fallback
    func googleMapWebURL() -> URL? {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://maps.google.com/?q=\(lat),\(lng)(\(encodedName))"
        return URL(string: urlString)
    }
}

// MARK: - Sample Data for Previews

extension Building {
    static let sampleBuildings: [Building] = [
        Building(
            code: "工綜館",
            name: "工程綜合館",
            aliases: ["工學院", "工綜", "Engineering Building", "工程館"],
            lat: 24.1201,
            lng: 120.6737,
            openHours: "週一至週五 8:00-22:00"
        ),
        Building(
            code: "圖書館",
            name: "中興大學圖書館",
            aliases: ["圖書", "Library", "lib", "圖資館"],
            lat: 24.1210,
            lng: 120.6745,
            openHours: "週一至週日 8:00-24:00"
        ),
        Building(
            code: "行政大樓",
            name: "行政大樓",
            aliases: ["行政", "Admin", "辦公室", "校長室"],
            lat: 24.1195,
            lng: 120.6730,
            openHours: "週一至週五 8:00-17:00"
        ),
        Building(
            code: "學生活動中心",
            name: "學生活動中心",
            aliases: ["學活", "Student Center", "活動中心", "社團"],
            lat: 24.1215,
            lng: 120.6750,
            openHours: "週一至週日 8:00-22:00"
        ),
        Building(
            code: "體育館",
            name: "體育館",
            aliases: ["體育", "Gym", "Sports Center", "運動"],
            lat: 24.1180,
            lng: 120.6720,
            openHours: "週一至週日 6:00-22:00"
        ),
        Building(
            code: "A601",
            name: "語言中心A601教室",
            aliases: ["語言中心", "Language Center", "外語"],
            lat: 24.1200,
            lng: 120.6740
        ),
        Building(
            code: "數學館",
            name: "數學系館",
            aliases: ["數學", "Math Building", "應數"],
            lat: 24.1205,
            lng: 120.6735,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "統計館",
            name: "統計學系館",
            aliases: ["統計", "Statistics", "統計系"],
            lat: 24.1190,
            lng: 120.6725,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "人文館",
            name: "人文社會科學大樓",
            aliases: ["人文", "文學院", "Humanities", "社科院"],
            lat: 24.1185,
            lng: 120.6750,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "農環大樓",
            name: "農業環境科學大樓",
            aliases: ["農環", "農學院", "Agriculture", "環科"],
            lat: 24.1220,
            lng: 120.6715,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "生科館",
            name: "生命科學館",
            aliases: ["生科", "Life Science", "生物", "生命科學"],
            lat: 24.1175,
            lng: 120.6760,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "化學館",
            name: "化學系館",
            aliases: ["化學", "Chemistry", "理學院"],
            lat: 24.1170,
            lng: 120.6745,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "物理館",
            name: "物理學系館",
            aliases: ["物理", "Physics", "應物"],
            lat: 24.1165,
            lng: 120.6730,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "管理學院",
            name: "管理學院大樓",
            aliases: ["管院", "Management", "商學院", "企管"],
            lat: 24.1160,
            lng: 120.6765,
            openHours: "週一至週五 8:00-21:00"
        ),
        Building(
            code: "餐廳",
            name: "學生餐廳",
            aliases: ["學餐", "Restaurant", "美食街", "吃飯"],
            lat: 24.1210,
            lng: 120.6720,
            openHours: "週一至週日 7:00-21:00"
        ),
        Building(
            code: "保健中心",
            name: "學生保健中心",
            aliases: ["保健", "Health Center", "醫務室", "看病"],
            lat: 24.1225,
            lng: 120.6735,
            openHours: "週一至週五 8:00-17:00"
        )
    ]
}
