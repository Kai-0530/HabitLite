//
//  RootTabView.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI

enum MainTab: Hashable { case today, analytics, settings }

struct RootTabView: View {
    @State private var selection: MainTab = .today
    @State private var analyticsRefreshToken = UUID()

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                TodayView()
                    .tabItem { Label("今天", systemImage: "checkmark.circle") }
                    .tag(MainTab.today)

                AnalyticsView()
                    .id(analyticsRefreshToken) // 切到統計即重建內容 觸發 onAppear
                    .tabItem { Label("統計", systemImage: "chart.bar") }
                    .tag(MainTab.analytics)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape") }
                    .tag(MainTab.settings)
            }
            .onChange(of: selection) { newValue in
                if newValue == .analytics {
                    analyticsRefreshToken = UUID() // 切到統計時刷新
                }
            }
        }
    }
}

