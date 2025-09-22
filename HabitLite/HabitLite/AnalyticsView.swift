//
//  AnalyticsView.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @State private var scope: Scope = .weekly
    
    enum Scope: String, CaseIterable, Identifiable { case weekly, monthly; var id: String { rawValue } }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("範圍", selection: $scope) {
                    Text("週").tag(Scope.weekly)
                    Text("月").tag(Scope.monthly)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if habits.isEmpty {
                    ContentUnavailableView("尚無資料", systemImage: "chart.bar")
                } else {
                    Chart(makeSeries(), id: \.label) { item in
                        BarMark(
                            x: .value("Period", item.label),
                            y: .value("完成率", item.rate * 100)
                        )
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 260)
                    .padding()

                }
                Spacer()
            }
            .navigationTitle("統計")
        }
    }
    
    // 取近 6 週 / 6 月
    private func makeSeries() -> [(label: String, rate: Double)] {
        let cal = Calendar.current
        let now = Date()
        
        let periods: [Date] = {
            switch scope {
            case .weekly:
                let startThisWeek = DateHelper.startOfWeek(now)
                return (0..<6).reversed().compactMap { cal.date(byAdding: .weekOfYear, value: -$0, to: startThisWeek) }
            case .monthly:
                let comps = cal.dateComponents([.year, .month], from: now)
                let startThisMonth = cal.date(from: comps)!
                return (0..<6).reversed().compactMap { cal.date(byAdding: .month, value: -$0, to: startThisMonth) }
            }
        }()
        
        return periods.map { start in
            let (done, total) = completion(for: start)
            let rate = total == 0 ? 0 : Double(done) / Double(total)
            let label: String = {
                let f = DateFormatter()
                f.locale = .current
                switch scope {
                case .weekly:
                    let end = cal.date(byAdding: .day, value: 6, to: start)!
                    f.dateFormat = "MM/dd"
                    return "\(f.string(from: start))–\(f.string(from: end))"
                case .monthly:
                    f.dateFormat = "yyyy/MM"
                    return f.string(from: start)
                }
            }()
            return (label, rate)
        }
    }
    
    // 將每個 habit 在該週/該月的「達成（1）/ 未達（0）」加總求平均
    private func completion(for start: Date) -> (done: Int, total: Int) {
        let cal = Calendar.current
        var days: [Date] = []
        switch scope {
        case .weekly:
            for d in 0..<7 { days.append(cal.date(byAdding: .day, value: d, to: start)!) }
        case .monthly:
            let range = cal.range(of: .day, in: .month, for: start)!
            for d in range { days.append(cal.date(byAdding: .day, value: d - 1, to: start)!) }
        }
        var done = 0, total = 0
        for day in days {
            for h in habits {
                // 以 habit.period 決定該天屬於哪個 periodKey
                let key = DateHelper.periodKey(for: h.period, on: day)
                let log = h.logs.first(where: { Calendar.current.isDate($0.periodKey, inSameDayAs: key) || $0.periodKey == key })
                let count = log?.count ?? 0
                let ok: Bool = (h.type == .atLeast) ? (count >= h.target) : (count <= h.target)
                done += ok ? 1 : 0
                total += 1
            }
        }
        return (done, total)
    }
}
