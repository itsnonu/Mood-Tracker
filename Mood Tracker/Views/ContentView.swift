//
//  ContentView.swift
//  Mood Tracker
//
//  Created by Salvador Nuno on 4/23/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // This fetches your saved moods from SwiftData
    @Query(sort: \MoodEntry.date, order: .reverse) private var entries: [MoodEntry]

    // State for the current "check-in"
    @State private var moodScore: Double = 3
    @State private var noteText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // --- 1. THE CHECK-IN SECTION ---
                VStack(alignment: .leading, spacing: 15) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .bold()
                    
                    // The dynamic color-coded slider
                    Slider(value: $moodScore, in: 1...5, step: 1)
                        .tint(moodColor(for: Int(moodScore)))
                    
                    HStack {
                        Text("Sad").font(.caption)
                        Spacer()
                        Text("\(Int(moodScore))").font(.headline)
                        Spacer()
                        Text("Happy").font(.caption)
                    }
                    
                    // --- 2. DYNAMIC PROMPTING ---
                    Text(dynamicPrompt)
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                    
                    TextField("Write a quick note...", text: $noteText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                    
                    Button(action: addEntry) {
                        Text("Save Mood")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(moodColor(for: Int(moodScore)))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)

                // --- 3. COLOR-CODED HISTORY ---
                List {
                    Section("History") {
                        ForEach(entries) { entry in
                            HStack {
                                Circle()
                                    .fill(moodColor(for: entry.score))
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading) {
                                    Text(entry.note.isEmpty ? "No note" : entry.note)
                                        .font(.body)
                                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Mood Tracker")
        }
    }

    // Logic for the dynamic question
    private var dynamicPrompt: String {
        if moodScore == 1 {
            return "Oh no, what made today feel like this?"
        } else if moodScore == 2 {
            return "Rough day, what happened?"
        } else if moodScore == 3 {
            return "Anything worth noting?"
        } else if moodScore == 4 {
            return "Pretty good day, care to share?"
        } else {
            return "Awesome, what's the occasion?"
        }
    }

    // Save the mood to SwiftData
    private func addEntry() {
        withAnimation {
            let newEntry = MoodEntry(date: Date(), score: Int(moodScore), note: noteText)
            modelContext.insert(newEntry)
            
            // Reset fields after saving
            noteText = ""
            moodScore = 3
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }

    // Helper function for the colors
    private func moodColor(for score: Int) -> Color {
        switch score {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return Color(red: 0.6, green: 0.9, blue: 0.4)
        case 5: return Color(red: 0.1, green: 0.7, blue: 0.1)
        default: return .gray
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
