//
//  Item.swift
//  app
//
//  Created by 劉李陽 on 2025/9/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
