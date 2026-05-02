//
//  MoodEntry.swift
//  Mood Tracker
//
//  Made by Salvador Nuno and Brandon Livdahl
//

import Foundation
import SwiftData

@Model
final class MoodEntry {
    var date: Date
    var score: Int // Mood value 1-5
    var note: String
    
    init(date: Date = .now, score: Int = 3, note: String = "") {
        self.date = date
        self.score = score
        self.note = note
    }
}
