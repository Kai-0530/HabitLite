//
//  AnalyticsView.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @State private var habits: [Habit] = []
    @State private var scope: Scope = .weekly
    enum Scope: String, CaseIterable, Identifiable { case weekly, monthly; var id: String { rawValue } }

    var body: some View {
        VStack(spacing: 12) {
            Picker("範圍", selection: $scope) {
                Text("週").tag(Scope.weekly)
                Text("月").tag(Scope.monthly)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if habits.isEmpty {
                ContentUnavailableView("尚無資料", systemImage: "chart.bar",
                    description: Text("到「今天」頁新增習慣後再回來看看吧"))
            } else {
                switch scope {
                case .weekly:  WeeklyGridView(habits: habits)
                case .monthly: MonthlyCalendarView(habits: habits)
                }
            }
            Spacer(minLength: 0)
        }
        .navigationTitle("統計")
        .onAppear(perform: reload)       // ← 切到統計分頁就會觸發（因為 .id 重建）
        .onChange(of: scope) { _ in reload() }
    }

    private func reload() {
        let desc = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        habits = (try? context.fetch(desc)) ?? []
    }
}

// MARK: - Weekly View

private struct WeeklyGridView: View {
    @Environment(\.modelContext) private var context
    let habits: [Habit]

    // 以「週一」為起點，支援左右切換週
    @State private var weekAnchor: Date = DateHelper.startOfWeek(Date())

    // 計算該週 7 天
    private var weekDays: [Date] {
        let cal = Calendar.current
        let start = weekAnchor
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private let cellW: CGFloat = 26
    private let cellH: CGFloat = 22
    private let gap: CGFloat = 6

    private var todayKey: Date { DateHelper.startOfDay(Date()) }
    private var totalBarWidth: CGFloat { cellW * 7 + gap * 6 }
    private var daysPassedInWeek: Int {
        weekDays.filter { DateHelper.startOfDay($0) <= todayKey }.count
    }
    private var progressWidth: CGFloat {
        let n = max(0, daysPassedInWeek)
        return cellW * CGFloat(n) + gap * CGFloat(max(0, n - 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 🔹 週導覽列（上一週 / 週區間 / 下一週）
            HStack {
                Button {
                    if let prev = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekAnchor) {
                        weekAnchor = prev
                    }
                } label: { Image(systemName: "chevron.left") }

                Spacer()
                Text(weekTitle(weekAnchor))
                    .font(.subheadline.weight(.semibold))
                Spacer()

                // 下一週若整週都在未來，就禁用
                let next = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekAnchor)!
                let nextWeekStart = DateHelper.startOfDay(next)
                let allowNext = nextWeekStart <= todayKey
                Button {
                    if allowNext { weekAnchor = next }
                } label: { Image(systemName: "chevron.right") }
                .disabled(!allowNext)
            }
            .padding(.horizontal, 8)

            // Header：M T W T F S S
            HStack(spacing: gap) {
                Spacer().frame(width: 12)
                Text("")
                Spacer()
                let labels = ["M","T","W","T","F","S","S"]
                ForEach(labels.indices, id: \.self) { i in
                    Text(labels[i])
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: cellW, height: 16)
                }
            }
            .padding(.horizontal, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(habits) { habit in
                        HStack(spacing: gap) {
                            Circle()
                                .fill(AppPalette.color(for: habit.colorHex))
                                .frame(width: 12, height: 12)

                            NavigationLink(destination: HabitAnalyticsView(habit: habit)) {
                                Text(habit.name).font(.subheadline).lineLimit(1)
                            }
                            .frame(minWidth: 80, alignment: .leading)

                            Spacer(minLength: 8)

                            if habit.period == .weekly {
                                // 以該週一為判斷點
                                let weekActive = weekDays.contains { isActive(habit, on: $0) && DateHelper.startOfDay($0) <= todayKey }
                                // 用 min(今天, 週末) 判定達標
                                let judgeDay = min(todayKey, weekDays.last!) // 直到今天或該週最後一天
                                let ok = isDone(habit, on: judgeDay)

                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.06))
                                        .frame(width: totalBarWidth, height: cellH)

                                    // 只填到今天（如果這週在未來就 0）
                                    let width = max(0, min(progressWidth, totalBarWidth))
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(weekActive ? (ok ? AppPalette.color(for: habit.colorHex) : Color.gray.opacity(0.15))
                                                         : Color.gray.opacity(0.06))
                                        .frame(width: width, height: cellH)
                                }
                                .frame(width: totalBarWidth, height: cellH)
                            } else {
                                ForEach(weekDays, id: \.self) { day in
                                    let isFuture = DateHelper.startOfDay(day) > todayKey
                                    let active = !isFuture && isActive(habit, on: day)
                                    let ok = active && isDone(habit, on: day)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            isFuture ? Color.gray.opacity(0.06)
                                                     : (active ? (ok ? AppPalette.color(for: habit.colorHex)
                                                                     : Color.gray.opacity(0.15))
                                                               : Color.gray.opacity(0.06))
                                        )
                                        .frame(width: cellW, height: cellH)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }

                    // Perfect 列（同樣以目前選擇的那一週）
                    HStack(spacing: gap) {
                        Spacer().frame(width: 12)
                        Text("Perfect")
                            .font(.subheadline.bold())
                            .frame(minWidth: 80, alignment: .leading)

                        Spacer(minLength: 8)

                        ForEach(weekDays, id: \.self) { day in
                            let isFuture = DateHelper.startOfDay(day) > todayKey
                            let perfect = !isFuture && isPerfectDay(day: day)
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isFuture ? Color.gray.opacity(0.06)
                                                   : (perfect ? Color.green.opacity(0.18) : Color.gray.opacity(0.10)))
                                    .frame(width: cellW, height: cellH)
                                if perfect {
                                    Image(systemName: "rosette")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func weekTitle(_ start: Date) -> String {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 6, to: start)!
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "MM/dd"
        return "\(f.string(from: start))–\(f.string(from: end))"
    }

    // 生效與完成（帶 startDate 容錯）
    private func isActive(_ habit: Habit, on day: Date) -> Bool {
        let d = DateHelper.startOfDay(day)
        let s = DateHelper.startOfDay(habit.startDate ?? habit.createdAt)
        return d >= s
    }
    private func isDone(_ habit: Habit, on day: Date) -> Bool {
        guard isActive(habit, on: day) else { return false }
        let (c, t, _) = HabitService.progress(for: habit, on: day, context: context)
        return habit.type == .atLeast ? (c >= t) : (c <= t)
    }
    private func isPerfectDay(day: Date) -> Bool {
        let active = habits.filter { isActive($0, on: day) }
        guard !active.isEmpty else { return false }
        for h in active where !isDone(h, on: day) { return false }
        return true
    }
}

// MARK: - Monthly View

private struct MonthlyCalendarView: View {
    @Environment(\.modelContext) private var context
    let habits: [Habit]
    @State private var currentMonthAnchor = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
    
    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2 // 週一
        return c
    }
    
    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: currentMonthAnchor)?.count ?? 30
    }
    
    private var firstWeekdayOffset: Int {
        // 月初對齊週一的前置空格數
        let weekday = cal.component(.weekday, from: currentMonthAnchor) // 1..7, 1=Sun
        // 轉成以週一為 1 的偏移：Mon(2)→0, Tue(3)→1, ..., Sun(1)→6
        return (weekday + 5) % 7
    }
    
    private var gridItems: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 8), count: 7) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 月份切換與標題
            HStack {
                Button {
                    if let prev = cal.date(byAdding: .month, value: -1, to: currentMonthAnchor) {
                        currentMonthAnchor = prev
                    }
                } label: { Image(systemName: "chevron.left") }
                
                Spacer()
                Text(monthTitle(currentMonthAnchor))
                    .font(.headline)
                Spacer()
                
                Button {
                    if let next = cal.date(byAdding: .month, value: 1, to: currentMonthAnchor) {
                        currentMonthAnchor = next
                    }
                } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal, 12)
            
            // 週標頭（Mon...Sun）
            HStack {
                ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { w in
                    Text(w)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // 月曆格子
            LazyVGrid(columns: gridItems, spacing: 10) {
                // 前導空白（用負索引，避免與 1...days 衝突）
                ForEach((-firstWeekdayOffset)..<0, id: \.self) { _ in
                    Color.clear.frame(height: 52)
                }
                
                // 每一天
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = cal.date(byAdding: .day, value: day - 1, to: currentMonthAnchor)!
                    let isFuture = DateHelper.startOfDay(date) > DateHelper.startOfDay(Date())
                    DayCircleCell(date: date,
                                  ratio: isFuture ? nil : completionRatio(on: date))
                }

            }
            .padding(.horizontal, 8)
        }
    }
    
    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "yyyy/MM"   // ← 小寫 y
        return f.string(from: date)
    }
    
    private func completionRatio(on date: Date) -> Double {
        var done = 0
        var total = 0
        for h in habits {
            // 只統計「startDate ≤ 當天」的習慣
            let d0 = DateHelper.startOfDay(date)
            let s0 = DateHelper.startOfDay(h.startDate)
            guard d0 >= s0 else { continue }
            let (c, t, _) = HabitService.progress(for: h, on: date, context: context)
            let ok = h.type == .atLeast ? (c >= t) : (c <= t)
            done += ok ? 1 : 0
            total += 1
        }
        return total == 0 ? 0 : Double(done) / Double(total)
    }
}

// MARK: - 圓環視圖（填滿比例）

private struct DayCircleCell: View {
    let date: Date
    let ratio: Double?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                if let r = ratio {
                    Circle()
                        .trim(from: 0, to: min(max(r, 0), 1))
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                Text(dayString(date))
                    .font(.caption2).bold()
            }
            .frame(height: 42)
        }
        .accessibilityLabel(Text("\(dateString(date)) 完成 \(Int((ratio ?? 0)*100))%"))
    }
    
    private func dayString(_ date: Date) -> String {
        let d = Calendar.current.component(.day, from: date)
        return String(d)
    }
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: date)
    }
}
