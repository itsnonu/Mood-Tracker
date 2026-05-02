//
//  ContentView.swift
//  Mood Tracker
//  Majority of the app functionality and logic comes from here
//
//  Made by Salvador Nuno and Brandon Livdahl
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // this grabs all the mood entries saved by swift data
    @Query(sort: \MoodEntry.date, order: .reverse) private var entries: [MoodEntry]
    
    // these store what the user typed on the today tab
    @State private var moodScore: Double = 3
    @State private var noteText: String = ""
    @State private var isEditingToday: Bool = true
    @State private var selectedEntryDate: Date = Date()
    
    // these store what month and day the user is viewing on the calender tab
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    // this is the calendar swift uses for date math like finding the next month
    private let calendar = Calendar.current
    
    // these columns make the calendar grid have 7 equal columns one for each day of the week
    private let calendarColumns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        TabView {
            NavigationStack {
                todayTab
                    .navigationTitle(shortDateTitle(for: selectedEntryDate))
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }
            
            NavigationStack {
                calendarTab
                    .navigationTitle("Calendar")
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
        }
        .onAppear {
            loadEntryForSelectedDate()
        }
    }
    
    // MARK: - Today Tab
    
    private var todayTab: some View {
        VStack(spacing: 20) {
            dayButtons
            
            if let savedEntry = selectedEntry, isEditingToday == false {
                savedTodayCard(for: savedEntry)
            } else {
                todayForm
            }
            
            Spacer()
        }
        .padding(.top)
    }
    // these are developer and demo buttons that would not be included in the final app. just for testing purposes!
    private var dayButtons: some View {
        HStack(spacing: 12) {
            Button {
                changeEntryDay(by: -1)
            } label: {
                Text("Previous Day")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            
            Button {
                changeEntryDay(by: 1)
            } label: {
                Text("Next Day")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
    
    private var todayForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(selectedEntry == nil ? "How are you feeling?" : "Edit")
                .font(.title2)
                .bold()
            
            // the slider lets the user pick a mood from 1 to 5
            Slider(value: $moodScore, in: 1...5, step: 1)
                .tint(moodColor(for: Int(moodScore)))
            
            HStack {
                Text("Sad")
                    .font(.caption)
                Spacer()
                Text("\(Int(moodScore))")
                    .font(.headline)
                Spacer()
                Text("Happy")
                    .font(.caption)
            }
            
            // this prompt changes depending on the mood score
            Text(dynamicPrompt)
                .font(.subheadline)
                .italic()
                .foregroundColor(.secondary)
            
            TextField("Write a quick note...", text: $noteText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3)
            
            Button(action: saveTodayEntry) {
                Text(selectedEntry == nil ? "Save Mood" : "Update Mood")
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
    }
    
    private func savedTodayCard(for entry: MoodEntry) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood saved for this day")
                        .font(.title2)
                        .bold()
                    
                    Text("Tap Edit if you want to change it.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Circle()
                    .fill(moodColor(for: entry.score))
                    .frame(width: 16, height: 16)
                
                Text("Mood: \(entry.score) out of 5")
                    .font(.headline)
            }
            
            Text(entry.note.isEmpty ? "No note saved for this day." : entry.note)
                .font(.body)
            
            Button(action: editTodayEntry) {
                Text("Edit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Tab
    
    private var calendarTab: some View {
        VStack(spacing: 20) {
            monthHeader
            
            LazyVGrid(columns: calendarColumns, spacing: 10) {
                ForEach(weekdayNames, id: \.self) { dayName in
                    Text(dayName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                }
                
                // blank spaces line up the first day of the month under the right weekday
                ForEach(0..<numberOfBlankDaysBeforeMonth(), id: \.self) { _ in
                    Text("")
                        .frame(height: 42)
                }
                
                // each real day gets a tappable circle colord by the saved mood
                ForEach(daysInMonth(), id: \.self) { day in
                    Button {
                        selectedDate = day
                    } label: {
                        Text("\(dayNumber(for: day))")
                            .font(.body)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(dayBackgroundColor(for: day))
                            .foregroundColor(dayTextColor(for: day))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            selectedDayDetails
            
            Spacer()
        }
        .padding(.top)
    }
    
    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            
            Spacer()
            
            Text(monthTitle(for: displayedMonth))
                .font(.title2)
                .bold()
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .padding(.horizontal)
    }
    
    private var selectedDayDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            
            if let entry = entry(for: selectedDate) {
                HStack {
                    Circle()
                        .fill(moodColor(for: entry.score))
                        .frame(width: 14, height: 14)
                    
                    Text("Mood: \(entry.score) out of 5")
                        .font(.subheadline)
                }
                
                Text(entry.note.isEmpty ? "No note saved for this day." : entry.note)
                    .font(.body)
            } else {
                Text("No mood saved for this day.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    // MARK: - Saving
    
    private var selectedEntry: MoodEntry? {
        entry(for: selectedEntryDate)
    }
    
    // this loads the saved entry for whatever day is picked
    private func loadEntryForSelectedDate() {
        if let savedEntry = selectedEntry {
            moodScore = Double(savedEntry.score)
            noteText = savedEntry.note
            isEditingToday = false
        } else {
            moodScore = 3
            noteText = ""
            isEditingToday = true
        }
    }
    
    // this saves one mood per day if that day already exists it updates that entry
    private func saveTodayEntry() {
        withAnimation {
            if let savedEntry = selectedEntry {
                savedEntry.score = Int(moodScore)
                savedEntry.note = noteText
                savedEntry.date = selectedEntryDate
            } else {
                let newEntry = MoodEntry(date: selectedEntryDate, score: Int(moodScore), note: noteText)
                modelContext.insert(newEntry)
            }
            
            selectedDate = selectedEntryDate
            displayedMonth = selectedEntryDate
            
            // after saving show the checkmark card instead of the form
            isEditingToday = false
        }
    }
    
    // this puts the picked days saved mood back into the form so the user can update it
    private func editTodayEntry() {
        if let savedEntry = selectedEntry {
            moodScore = Double(savedEntry.score)
            noteText = savedEntry.note
        }
        
        isEditingToday = true
    }
    
    // this moves the today tab forward or backward
    private func changeEntryDay(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value, to: selectedEntryDate) {
            selectedEntryDate = newDate
            selectedDate = newDate
            displayedMonth = newDate
            loadEntryForSelectedDate()
        }
    }
    
    // MARK: - Calendar Helpers
    
    // finds the saved mood entry for a specific day
    private func entry(for date: Date) -> MoodEntry? {
        for entry in entries {
            if isSameDay(entry.date, date) {
                return entry
            }
        }
        
        return nil
    }
    
    // checks if two date values are on the same calendar day
    private func isSameDay(_ firstDate: Date, _ secondDate: Date) -> Bool {
        calendar.isDate(firstDate, inSameDayAs: secondDate)
    }
    
    // builds an array of every date in the month we are looking at
    private func daysInMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        
        var days: [Date] = []
        
        for dayNumber in range {
            var dateParts = calendar.dateComponents([.year, .month], from: displayedMonth)
            dateParts.day = dayNumber
            
            if let date = calendar.date(from: dateParts) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // counts how many blank spaces are needed before day 1 in the month grid
    private func numberOfBlankDaysBeforeMonth() -> Int {
        let firstDay = firstDayOfMonth(for: displayedMonth)
        let weekday = calendar.component(.weekday, from: firstDay)
        
        // calendar weekday numbers start at 1 for sunday so subtract 1 to get blank spaces
        return weekday - 1
    }
    
    // moves the calendar to a different month
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            selectedDate = firstDayOfMonth(for: newMonth)
        }
    }
    
    // gets the first day of a month from any date inside that month
    private func firstDayOfMonth(for date: Date) -> Date {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: parts) ?? date
    }
    
    // gets the day number from a date like 14 from may 14
    private func dayNumber(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }
    
    // shows the month title at the top of the calendar
    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
    
    // shows the picked date at the top of the today tab
    private func shortDateTitle(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // these are the weekday labels shown above the calendar grid
    private var weekdayNames: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    // MARK: - Colors And Text
    
    // the selected date gets a darker color so it is easy to see what was tapped
    private func dayBackgroundColor(for date: Date) -> Color {
        if let entry = entry(for: date) {
            return moodColor(for: entry.score)
        } else if isSameDay(date, selectedDate) {
            return Color(.systemGray4)
        } else {
            return Color(.systemGray6)
        }
    }
    
    // white text is easier to read on the darker mood colors
    private func dayTextColor(for date: Date) -> Color {
        if entry(for: date) != nil {
            return .white
        } else {
            return .primary
        }
    }
    
    // logic for the dynamic question on the today tab
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
            return "Awesome! What's the occasion?"
        }
    }
    
    // function that turns mood scores into colors
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
