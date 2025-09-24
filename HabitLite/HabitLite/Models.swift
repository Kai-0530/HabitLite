//
//  Models.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import Foundation
import SwiftData

enum HabitType: String, Codable, CaseIterable, Identifiable {
    case atLeast  // 養成：count >= target 視為完成
    case atMost   // 戒除：count <= target 視為完成
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .atLeast: return "好目標"
        case .atMost:  return "壞習慣"
        }
    }
}

enum Period: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    var id: String { rawValue }
    
    var displayName: String {
        self == .daily ? "每日" : "每週"
    }
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var type: HabitType
    var period: Period
    var target: Int
    var createdAt: Date
    var startDate: Date
    @Relationship(deleteRule: .cascade) var logs: [HabitLog] = []
    
    init(name: String, colorHex: String, type: HabitType, period: Period, target: Int) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.type = type
        self.period = period
        self.target = max(0, target)
        self.createdAt = .now
        self.startDate = .now
    }
}

@Model
final class HabitLog {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    var periodKey: Date
    var count: Int
    
    init(habitID: UUID, periodKey: Date, count: Int = 0) {
        self.id = UUID()
        self.habitID = habitID
        self.periodKey = periodKey
        self.count = max(0, count)
    }
}
