//  CountdownManager.swift
//  DateReminder

import SwiftUI

enum DisplayMode: String, CaseIterable, Codable {
    case percent, days, hours
}

struct DailyQuote {
    let text: String
    let author: String
}

class CountdownManager: ObservableObject {
    @Published var events:        [CountdownEvent] = []
    @Published var selectedID:    UUID?            = CountdownEvent.tomorrowID
    @Published var displayMode:   DisplayMode      = .percent
    @Published var statusBarText: String           = "Loading..."
    @Published var todaysQuote:   DailyQuote       = DailyQuote(text: "", author: "")

    @Published var currentLanguage: String = UserDefaults.standard.string(forKey: "AppLanguage") ?? "vi"
    var isVI: Bool { currentLanguage == "vi" }

    var allEvents: [CountdownEvent] { [.tomorrow(name: isVI ? "Ngày mai" : "Tomorrow")] + events }
    var selectedEvent: CountdownEvent? { allEvents.first { $0.id == selectedID } ?? allEvents.first }

    private var refreshTimer: Timer?
    private let saveKey = "SavedCountdownEvents"
    private let modeKey = "SavedDisplayMode"

    private let quotePool: [DailyQuote] = [
        DailyQuote(text: "Muốn thành công thì phải chấp nhận mạo hiểm, nguy hiểm nhưng trong tầm kiểm soát.", author: "Khuyết danh"),
        DailyQuote(text: "Học, học nữa, học mãi", author: "Chủ tịch Hồ Chí Minh"),
        DailyQuote(text: "Stay hungry, stay foolish.", author: "Steve Jobs"),
    ]

    init() {
        loadEvents()
        if let savedMode = UserDefaults.standard.string(forKey: modeKey), let mode = DisplayMode(rawValue: savedMode) {
            self.displayMode = mode
        }
        pickDailyQuote()
        updateStatusBarText()
        startRefreshTimer()
    }

    deinit { refreshTimer?.invalidate() }

    func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CountdownEvent].self, from: data) {
            self.events = decoded
        } else {
            // DEMO BẠN YÊU CẦU: THPT & TSA
            let cal = Calendar.current
            let thptDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 11))!
            let tsaDate = cal.date(from: DateComponents(year: 2026, month: 5, day: 16))!
            
            self.events = [
                CountdownEvent(name: "Kì thi THPT", date: thptDate, startDate: Date()),
                CountdownEvent(name: "TSA", date: tsaDate, startDate: Date())
            ]
        }
    }

    func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    func addNewEvent(name: String, targetDate: Date) {
        let newEvent = CountdownEvent(name: name, date: targetDate, startDate: Date())
        DispatchQueue.main.async {
            self.events.append(newEvent)
            self.selectedID = newEvent.id
            self.saveEvents()
            self.updateStatusBarText()
        }
    }

    func deleteSelectedEvent() {
        guard let current = selectedEvent, current.id != CountdownEvent.tomorrowID else { return }
        DispatchQueue.main.async {
            self.events.removeAll { $0.id == current.id }
            self.selectedID = CountdownEvent.tomorrowID
            self.saveEvents()
            self.updateStatusBarText()
        }
    }

    func cycleDisplayMode() {
        let all = DisplayMode.allCases
        if let idx = all.firstIndex(of: displayMode) {
            let next = all[(idx + 1) % all.count]
            displayMode = next
            UserDefaults.standard.set(next.rawValue, forKey: modeKey)
            updateStatusBarText()
        }
    }

    func toggleLanguage() {
        currentLanguage = isVI ? "en" : "vi"
        UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
        updateStatusBarText()
    }

    func updateStatusBarText() {
        let text: String
        switch (displayMode, selectedEvent) {
        case (_, nil):
            text = isVI ? "Không có sự kiện" : "No events"
        case (.percent, let event?):
            let p = String(format: "%.1f", event.percentLeft)
            text = isVI ? "\(p)% cho đến \(event.name)" : "\(p)% until \(event.name)"
        case (.days, let event?):
            text = isVI ? "\(event.daysLeft) ngày cho đến \(event.name)" : "\(event.daysLeft) days left until \(event.name)"
        case (.hours, let event?):
            text = isVI ? "\(event.hoursLeft) giờ cho đến \(event.name)" : "\(event.hoursLeft) hours left until \(event.name)"
        }
        // Skip identical writes: every @Published set re-renders the popover.
        if text != statusBarText { statusBarText = text }
    }

    func displayModeLabel() -> String {
        switch displayMode {
        case .percent: return isVI ? "% Còn Lại" : "% Left"
        case .days: return isVI ? "Chỉ Ngày" : "Days Only"
        case .hours: return isVI ? "Chỉ Giờ" : "Hours Only"
        }
    }

    func selectEvent(_ event: CountdownEvent) {
        DispatchQueue.main.async {
            self.selectedID = event.id
            self.updateStatusBarText()
        }
    }

    func pickDailyQuote() { todaysQuote = quotePool.randomElement()! }

    private func startRefreshTimer() {
        // Nothing in the menu bar changes faster than ~1 min; tolerance lets macOS coalesce wakeups.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateStatusBarText()
        }
        refreshTimer?.tolerance = 10
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }
}
