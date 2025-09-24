//
//  HabitAnalyticsView.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI
import SwiftData

struct HabitAnalyticsView: View {
    @Environment(\.modelContext) private var context
    let habit: Habit

    @State private var scope: Scope = .monthly
    enum Scope: String, CaseIterable, Identifiable { case monthly, yearly; var id: String { rawValue } }

    var body: some View {
        VStack(spacing: 12) {
            Picker("範圍", selection: $scope) {
                Text("月").tag(Scope.monthly)
                Text("年").tag(Scope.yearly)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch scope {
            case .monthly:
                PerHabitMonthlyCalendar(habit: habit)
            case .yearly:
                PerHabitYearlyHeatmap(habit: habit)
            }
            Spacer(minLength: 0)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 單一習慣：月曆（可點日看詳情）
private struct PerHabitMonthlyCalendar: View {
    @Environment(\.modelContext) private var context
    let habit: Habit

    @State private var monthAnchor = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
    @State private var selectedDay: SelectedDay?

    private var cal: Calendar { var c = Calendar.current; c.firstWeekday = 2; return c }
    private var daysInMonth: Int { cal.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30 }
    private var firstWeekdayOffset: Int { (cal.component(.weekday, from: monthAnchor) + 5) % 7 }
    private var cols: [GridItem] { Array(repeating: .init(.flexible(), spacing: 8), count: 7) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { monthAnchor = cal.date(byAdding: .month, value: -1, to: monthAnchor)! } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(title(monthAnchor)).font(.headline)
                Spacer()
                Button { monthAnchor = cal.date(byAdding: .month, value: 1, to: monthAnchor)! } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 12)

            HStack {
                ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) {
                    Text($0).font(.caption.bold()).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in Color.clear.frame(height: 52) }

                ForEach(1...daysInMonth, id: \.self) { d in
                    let date = cal.date(byAdding: .day, value: d - 1, to: monthAnchor)!
                    let ratio = dailyRatio(on: date)
                    DayCircle(date: date, ratio: ratio, tint: AppPalette.color(for: habit.colorHex))
                        .onTapGesture {
                            guard ratio != nil else { return } // 未來或未生效就不開
                            selectedDay = .init(date: date)
                        }
                }
            }
            .padding(.horizontal, 8)
        }
        .sheet(item: $selectedDay) { sel in
            PerHabitDayDetail(date: sel.date, habit: habit)
                .presentationDetents([.medium, .large])
        }
    }

    private func title(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "yyyy/MM"; return f.string(from: date)
    }
    private func dailyRatio(on date: Date) -> Double? {
        let today = DateHelper.startOfDay(Date())
        let d0 = DateHelper.startOfDay(date)
        let start = DateHelper.startOfDay(habit.startDate ?? habit.createdAt)
        guard d0 <= today, d0 >= start else { return nil }
        let (c, t, _) = HabitService.progress(for: habit, on: date, context: context)
        let ok = habit.type == .atLeast ? (c >= t) : (c <= t)
        return ok ? 1.0 : 0.0 // 單一習慣：當日非完成即未完成（0 或 1）
    }

    private struct SelectedDay: Identifiable { let date: Date; var id: Date { date } }
}

private struct DayCircle: View {
    let date: Date
    let ratio: Double?           // nil = 未來或未開始
    let tint: Color

    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 6)
            if let r = ratio {
                Circle()
                    .trim(from: 0, to: min(max(r, 0), 1))
                    .stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(dayString(date)).font(.caption2).bold()
        }
        .frame(height: 42)
        .opacity(ratio == nil ? 0.5 : 1)
    }
    private func dayString(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }
}

// 單一習慣：點某天的詳情
private struct PerHabitDayDetail: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let date: Date
    let habit: Habit

    var body: some View {
        List {
            let (c, t, _) = HabitService.progress(for: habit, on: date, context: context)
            let ok = habit.type == .atLeast ? (c >= t) : (c <= t)
            HStack(spacing: 12) {
                Circle().fill(AppPalette.color(for: habit.colorHex)).frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name).font(.headline)
                    Text("\(habit.type.displayName)・目標 \(t) ・\(c)/\(t)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.title3).foregroundStyle(ok ? .green : .secondary)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle(dateTitle(date))
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
    }

    private func dateTitle(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "yyyy/MM/dd (EEE)"; return f.string(from: date)
    }
}

private struct PerHabitYearlyHeatmap: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    @State private var year: Int = Calendar.current.component(.year, from: Date())

    private var cal: Calendar { var c = Calendar.current; c.firstWeekday = 2; return c }
    private let monthGridCols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3) // 3 欄排 12 個月

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 年份切換列
                HStack {
                    Button { year -= 1 } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text("\(year) 年").font(.headline)
                    Spacer()
                    Button { year += 1 } label: { Image(systemName: "chevron.right") }
                }
                .padding(.horizontal, 12)

                // 3x4 月份拼圖
                LazyVGrid(columns: monthGridCols, alignment: .leading, spacing: 12) {
                    ForEach(1...12, id: \.self) { m in
                        MonthHeatmapMini(year: year, month: m, habit: habit, context: context, calendar: cal)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }
}

private struct MonthHeatmapMini: View {
    let year: Int, month: Int
    let habit: Habit
    let context: ModelContext
    let calendar: Calendar

    // 更小的方格
    private let cellH: CGFloat = 8
    private let spacing: CGFloat = 2

    private var startOfMonth: Date { calendar.date(from: .init(year: year, month: month, day: 1))! }
    private var daysInMonth: Int { calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30 }
    private var firstWeekdayOffset: Int { (calendar.component(.weekday, from: startOfMonth) + 5) % 7 }
    private var cols: [GridItem] { Array(repeating: .init(.flexible(), spacing: spacing), count: 7) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthTitle())
                .font(.caption.bold())

            LazyVGrid(columns: cols, spacing: spacing) {
                ForEach((-firstWeekdayOffset)..<0, id: \.self) { _ in
                    Color.clear.frame(height: cellH)
                }
                ForEach(1...daysInMonth, id: \.self) { d in
                    let date = calendar.date(byAdding: .day, value: d - 1, to: startOfMonth)!
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color(for: date))
                        .frame(height: cellH)
                }
            }
        }
    }

    private func color(for date: Date) -> Color {
        let today = DateHelper.startOfDay(Date())
        let d0 = DateHelper.startOfDay(date)
        let start = DateHelper.startOfDay(habit.startDate ?? habit.createdAt)
        guard d0 <= today, d0 >= start else { return .gray.opacity(0.06) }
        let (c, t, _) = HabitService.progress(for: habit, on: date, context: context)
        let ok = habit.type == .atLeast ? (c >= t) : (c <= t)
        return ok ? AppPalette.color(for: habit.colorHex).opacity(0.85) : .gray.opacity(0.12)
    }

    private func monthTitle() -> String {
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "MMM"; return f.string(from: startOfMonth)
    }
}
