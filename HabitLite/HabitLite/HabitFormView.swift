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
                    Stepper("目標次數：\(target)", value: $target, in: 0...999)
                }
                Section("顏色（Hex）") {
                    TextField("#RRGGBB", text: $colorHex)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Text("預覽")
                        Spacer()
                        Circle().fill(Color(hex: colorHex) ?? .fallback).frame(width: 24, height: 24)
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
        } else {
            let h = Habit(name: name, colorHex: colorHex, type: type, period: period, target: target)
            context.insert(h)
        }
        try? context.save()
        dismiss()
    }
}
