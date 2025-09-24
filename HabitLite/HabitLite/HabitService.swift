//
//  HabitService.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import Foundation
import SwiftData

struct HabitService {
    static func currentLog(for habit: Habit, date: Date = .now, context: ModelContext) -> HabitLog {
        let key = DateHelper.periodKey(for: habit.period, on: date)
        if let found = habit.logs.first(where: { Calendar.current.isDate($0.periodKey, inSameDayAs: key) || $0.periodKey == key }) {
            return found
        }
        let newLog = HabitLog(habitID: habit.id, periodKey: key, count: 0)
        habit.logs.append(newLog)
        return newLog
    }
    
    static func increment(_ habit: Habit, by delta: Int = 1, date: Date = .now, context: ModelContext) {
        let log = currentLog(for: habit, date: date, context: context)
        log.count = max(0, log.count + delta)
        try? context.save()
        NotificationCenter.default.post(name: .habitDataDidChange, object: nil) 
    }
    
    static func progress(for habit: Habit, on date: Date = .now, context: ModelContext) -> (count: Int, target: Int, done: Bool) {
        let log = currentLog(for: habit, date: date, context: context)
        let c = log.count
        let t = max(0, habit.target)
        let done: Bool = {
            switch habit.type {
            case .atLeast: return c >= t
            case .atMost:  return c <= t
            }
        }()
        return (c, t, done)
    }
}
