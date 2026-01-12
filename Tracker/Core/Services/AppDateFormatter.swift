//
//  AppDateFormatter.swift
//  Tracker
//
//  Created by Artem Kuzmenko on 15.11.2025.
//


import Foundation

struct AppDateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
}
