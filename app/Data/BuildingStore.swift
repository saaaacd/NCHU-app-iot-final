//
//  BuildingStore.swift
//  初興 (NCHUHelper)
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation
import Combine

@MainActor
final class BuildingStore: ObservableObject {
    @Published var all: [Building] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Loading Methods
    
    /// Load buildings from Resources/Buildings.json
    func load() {
        guard !isLoading else { return } // Prevent multiple simultaneous loads
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let buildings = try await loadBuildingsData()
                
                await MainActor.run {
                    self.all = buildings.sorted { $0.code < $1.code }
                    self.isLoading = false
                    print("✅ Successfully loaded \(buildings.count) buildings from JSON")
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "載入建築資料失敗，使用預設資料: \(error.localizedDescription)"
                    print("❌ Failed to load buildings from JSON: \(error.localizedDescription)")
                    // Fallback to sample data
                    self.loadSampleData()
                }
            }
        }
    }
    
    /// Load buildings data from file (off main thread)
    private func loadBuildingsData() async throws -> [Building] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let url = Bundle.main.url(forResource: "Buildings", withExtension: "json") else {
                        print("📝 Buildings.json not found, using sample data")
                        continuation.resume(returning: Building.sampleBuildings)
                        return
                    }
                    
                    let data = try Data(contentsOf: url)
                    let buildings = try JSONDecoder().decode([Building].self, from: data)
                    continuation.resume(returning: buildings)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Load sample data as fallback
    private func loadSampleData() {
        all = Building.sampleBuildings
        isLoading = false
        print("Loaded \(all.count) buildings from sample data")
    }
    
    // MARK: - Search Methods
    
    /// Search buildings by keyword (case-insensitive)
    /// Searches in code, name, and aliases
    func search(matching keyword: String) -> [Building] {
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return all
        }
        
        return all.filter { building in
            building.matches(keyword: keyword)
        }
    }
    
    /// Find exact building by code
    func findByCode(_ code: String) -> Building? {
        return all.first { $0.code.lowercased() == code.lowercased() }
    }
    
    /// Find buildings in a specific area/category
    func findByCategory(_ category: String) -> [Building] {
        let lowercaseCategory = category.lowercased()
        return all.filter { building in
            building.code.lowercased().contains(lowercaseCategory) ||
            building.name.lowercased().contains(lowercaseCategory) ||
            building.aliases.contains { $0.lowercased().contains(lowercaseCategory) }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get all building codes for quick lookup
    var allCodes: [String] {
        return all.map { $0.code }.sorted()
    }
    
    /// Get all unique aliases for search suggestions
    var allAliases: [String] {
        let aliases = all.flatMap { $0.aliases }
        return Array(Set(aliases)).sorted()
    }
    
    /// Check if store has any buildings loaded
    var isEmpty: Bool {
        return all.isEmpty
    }
    
    /// Get count of loaded buildings
    var count: Int {
        return all.count
    }
}
