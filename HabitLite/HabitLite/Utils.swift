//
//  Utils.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import Foundation
import SwiftUI

struct DateHelper {
    static func startOfDay(_ date: Date, in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
    static func startOfWeek(_ date: Date, in calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // 1=Sun, 2=Mon；周一起始
        let startOfDay = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: startOfDay)
        // 對齊到周一
        let diff = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -diff, to: startOfDay)!
    }
    static func periodKey(for period: Period, on date: Date) -> Date {
        switch period {
        case .daily:  return startOfDay(date)
        case .weekly: return startOfWeek(date)
        }
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        guard let v = UInt64(s, radix: 16) else { return nil }
        let r, g, b: Double
        switch s.count {
        case 6:
            r = Double((v & 0xFF0000) >> 16) / 255
            g = Double((v & 0x00FF00) >> 8) / 255
            b = Double(v & 0x0000FF) / 255
        default:
            return nil
        }
        self = Color(red: r, green: g, blue: b)
    }
    static var fallback: Color { .accentColor }
}
extension Notification.Name {
    static let habitDataDidChange = Notification.Name("HabitDataDidChange")
}
