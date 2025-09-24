//
//  HabitLiteApp.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI
import SwiftData

@main
struct HabitLiteApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [Habit.self, HabitLog.self]) 
    }
}
