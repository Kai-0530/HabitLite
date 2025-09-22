//
//  AppPalette.swift
//  HabitLite
//
//  Created by 黃彥愷 on 2025/9/22.
//

import SwiftUI

enum AppPalette {
    static let hexes: [String] = [
        "#FF6B6B", "#FFA94D", "#FFD43B", "#69DB7C",
        "#38D9A9", "#4DABF7", "#748FFC", "#B197FC",
        "#F783AC", "#FF8787", "#FCC419", "#63E6BE"
    ]
    
    static func color(for hex: String) -> Color {
        Color(hex: hex) ?? .accentColor
    }
}
