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
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var showingForm = false
    @State private var editing: Habit?
    
    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView("尚無習慣", systemImage: "square.and.pencil",
                                           description: Text("點右上角「＋」建立第一個習慣"))
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitRow(habit: habit)
                                .contentShape(Rectangle())
                                .onTapGesture { HabitService.increment(habit, context: context) }
                                .swipeActions {
                                    Button("編輯") { editing = habit }
                                        .tint(.blue)
                                    Button(role: .destructive) {
                                        context.delete(habit)
                                        try? context.save()
                                    } label: { Text("刪除") }
                                }
                        }
                    }
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
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $editing) { item in
                HabitFormView(editing: item)
            }
        }
    }
}

private struct HabitRow: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    
    var body: some View {
        let p = HabitService.progress(for: habit, context: context)
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: habit.colorHex) ?? .fallback)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name).font(.headline)
                Text("\(habit.type.displayName)・\(habit.period.displayName)目標 \(p.target)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(p.count)/\(p.target)")
                .monospaced()
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(p.done ? .green.opacity(0.15) : .gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 6)
    }
}
