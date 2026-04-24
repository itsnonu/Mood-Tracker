//
//  MoodEntry.swift
//  Mood Tracker
//
//  Created by Salvador Nuno on 4/23/26.
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
