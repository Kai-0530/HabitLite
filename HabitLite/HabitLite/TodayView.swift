//
//  TodayView.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @State private var habits: [Habit] = []
    @State private var showingForm = false
    @State private var editing: Habit?
    @State private var selectedDate = Date() // 可選日期（預設今天）

    var body: some View {
        Group {
            if habits.isEmpty {
                ContentUnavailableView("尚無習慣", systemImage: "square.and.pencil",
                                       description: Text("點右上角「＋」建立第一個習慣"))
            } else {
                List {
                    Section {
                        DatePicker("選擇日期", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    } footer: {
                    }
                    // 依「是否生效」與「好/壞」分類
                    let activeGood = habits.filter { isActive($0, on: selectedDate) && $0.type == .atLeast }
                    let activeBad  = habits.filter { isActive($0, on: selectedDate) && $0.type == .atMost  }
                    let notStarted = habits.filter { !isActive($0, on: selectedDate) }

                    if !activeGood.isEmpty {
                        Section("好習慣") {
                            ForEach(activeGood) { habit in
                                HabitRow(habit: habit,
                                         date: selectedDate,
                                         enabled: true,
                                         onChanged: reload)
                                .swipeActions {
                                    Button("編輯") { editing = habit }.tint(.blue)
                                    Button(role: .destructive) {
                                        context.delete(habit); try? context.save(); reload()
                                    } label: { Text("刪除") }
                                }
                            }
                        }
                    }

                    if !activeBad.isEmpty {
                        Section("壞習慣") {
                            ForEach(activeBad) { habit in
                                HabitRow(habit: habit,
                                         date: selectedDate,
                                         enabled: true,
                                         onChanged: reload)
                                .swipeActions {
                                    Button("編輯") { editing = habit }.tint(.blue)
                                    Button(role: .destructive) {
                                        context.delete(habit); try? context.save(); reload()
                                    } label: { Text("刪除") }
                                }
                            }
                        }
                    }

                    if !notStarted.isEmpty {
                        Section("未開始") {
                            ForEach(notStarted) { habit in
                                HabitRow(habit: habit,
                                         date: selectedDate,
                                         enabled: false,   // 未生效 停用+-
                                         onChanged: reload)
                                .swipeActions {
                                    Button("編輯") { editing = habit }.tint(.blue)
                                    Button(role: .destructive) {
                                        context.delete(habit); try? context.save(); reload()
                                    } label: { Text("刪除") }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("今天")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingForm) {
            HabitFormView()
                .onDisappear(perform: reload)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $editing) { item in
            HabitFormView(editing: item)
                .onDisappear(perform: reload)
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        var desc = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        habits = (try? context.fetch(desc)) ?? []
    }

    // 判斷該習慣在某天是否已生效（startDate 無值則回退用 createdAt）
    private func isActive(_ habit: Habit, on day: Date) -> Bool {
        let d = DateHelper.startOfDay(day)
        let s = DateHelper.startOfDay(habit.startDate ?? habit.createdAt)
        return d >= s
    }
}

// MARK: - Row（支援指定日期 + 可停用）
private struct HabitRow: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    let date: Date
    let enabled: Bool               // 未開始: false（停用 +/−）
    var onChanged: () -> Void
    @State private var tick = 0

    var body: some View {
        let p = HabitService.progress(for: habit, on: date, context: context)

        HStack(spacing: 10) {
            Circle()
                .fill(AppPalette.color(for: habit.colorHex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.body)
                Text("\(habit.type.displayName)・\(habit.period.displayName)目標 \(p.target)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("\(p.count)/\(p.target)")
                .monospaced()
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(p.done ? .green.opacity(0.15) : .gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 8) {
                Button {
                    HabitService.increment(habit, by: -1, date: date, context: context)
                    tick &+= 1
                    DispatchQueue.main.async { onChanged() }
                } label: { Image(systemName: "minus.circle").font(.title3) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("減一"))
                .disabled(!enabled)

                Button {
                    HabitService.increment(habit, by: 1, date: date, context: context)
                    tick &+= 1
                    DispatchQueue.main.async { onChanged() }
                } label: { Image(systemName: "plus.circle").font(.title3) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("加一"))
                .disabled(!enabled)
            }
        }
        .opacity(enabled ? 1.0 : 0.5)
        .id(tick)
        .padding(.vertical, 6)
    }
}
