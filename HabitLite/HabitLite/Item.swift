//
//  Item.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
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
