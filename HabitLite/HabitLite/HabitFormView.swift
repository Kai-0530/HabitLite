//
//  HabitFormView.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var editing: Habit?
    @State private var name = ""
    @State private var colorHex = "#4F7CAC"
    @State private var type: HabitType = .atLeast
    @State private var startDate: Date = .now
    @State private var period: Period = .daily
    @State private var target: Int = 1
    
    init(editing: Habit? = nil) {
        self.editing = editing
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("名稱", text: $name)
                    Picker("類型", selection: $type) {
                        ForEach(HabitType.allCases) { t in Text(t.displayName).tag(t) }
                    }
                    Picker("週期", selection: $period) {
                        ForEach(Period.allCases) { p in Text(p.displayName).tag(p) }
                    }
                    Section("開始日期") {
                        DatePicker("從這天開始計算", selection: $startDate, displayedComponents: .date)
                    }
                    Stepper("目標次數：\(target)", value: $target, in: 0...999)
                }
                Section("顏色") {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AppPalette.hexes, id: \.self) { hex in
                            ZStack {
                                Circle()
                                    .fill(AppPalette.color(for: hex))
                                    .frame(width: 34, height: 34)

                                if hex == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture { colorHex = hex }
                            .accessibilityLabel(Text("選擇顏色"))
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("目前顏色")
                        Spacer()
                        Circle()
                            .fill(AppPalette.color(for: colorHex))
                            .frame(width: 24, height: 24)
                    }
                }

            }
            .navigationTitle(editing == nil ? "新增習慣" : "編輯習慣")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") { save() }.bold().disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = editing {
                    name = e.name
                    colorHex = e.colorHex
                    type = e.type
                    period = e.period
                    target = e.target
                    startDate = e.startDate
                }
            }
        }
    }
    
    private func save() {
        if let e = editing {
            e.name = name
            e.colorHex = colorHex
            e.type = type
            e.period = period
            e.target = target
            e.startDate = DateHelper.startOfDay(startDate) // ← 建議對齊零點
        } else {
            let h = Habit(name: name, colorHex: colorHex, type: type, period: period, target: target)
            h.startDate = DateHelper.startOfDay(startDate) // ← 新增
            context.insert(h)
        }
        try? context.save()
        NotificationCenter.default.post(name: .habitDataDidChange, object: nil)
        dismiss()

    }
}
