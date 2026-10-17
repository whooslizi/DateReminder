//
//  BeautifulCountdownView.swift
//  DateReminder
//
//  Created by Hodaka on 7/4/26.
//

import SwiftUI

struct BeautifulCountdownView: View {
    @EnvironmentObject var countdownManager: CountdownManager

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    @State private var isAddingNew = false
    @State private var newEventName = ""
    @State private var newEventDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            if let event = countdownManager.selectedEvent {
                // Redraw once a minute only while the popover is on screen.
                TimelineView(.everyMinute) { _ in mainCard(event) }
            } else {
                Text(countdownManager.isVI ? "Không có sự kiện" : "No upcoming events")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider().background(Color.white.opacity(0.12))
            eventPicker
            
            Divider().background(Color.white.opacity(0.12))
            adminControls
            
            Divider().background(Color.white.opacity(0.12))
            quoteSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func mainCard(_ event: CountdownEvent) -> some View {
        let t = event.detailedTimeLeft
        let isVI = countdownManager.isVI
        
        VStack(spacing: 4) {
            Text(event.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(2)
                .textCase(.uppercase)
                .padding(.top, 16)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                timeBlock(value: t.days, unit: isVI ? "ngày" : "days")
                timeBlock(value: t.hours, unit: isVI ? "giờ" : "hours")
                timeBlock(value: t.minutes, unit: isVI ? "phút" : "minutes")
            }
            .padding(.top, 10)

            let deadlinePrefix = isVI ? "Ngày cuối:" : "Deadline:"
            Text("\(deadlinePrefix) \(dateFormatter.string(from: event.date))")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 10)

            progressBar(percent: event.percentLeft,
                        colors: [Color(red:0.45, green:0.65, blue:1), Color(red:0.75, green:0.45, blue:1)])
                .padding(.top, 12)
            Text(String(format: "%.3f%%", event.percentLeft))
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .monospacedDigit()

            let today = countdownManager.percentUntilTomorrow
            progressBar(percent: today,
                        colors: [Color(red:1, green:0.75, blue:0.35), Color(red:1, green:0.45, blue:0.45)])
                .padding(.top, 8)
            Text(String(format: isVI ? "Hôm nay còn %.1f%%" : "%.1f%% until tomorrow", today))
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .monospacedDigit()
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private func progressBar(percent: Double, colors: [Color]) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(percent / 100.0))
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private func timeBlock(value: Int, unit: String) -> some View {
        VStack(spacing: -2) {
            Text("\(value)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            Text(unit)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var eventPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(countdownManager.events, id: \.id) { event in
                    let isSelected = countdownManager.selectedEvent?.id == event.id
                    Button {
                        withAnimation { countdownManager.selectEvent(event) }
                    } label: {
                        Text(event.name)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var adminControls: some View {
        let isVI = countdownManager.isVI
        
        return VStack(spacing: 12) {
            if isAddingNew {
                HStack {
                    TextField(isVI ? "Tên sự kiện..." : "Event name...", text: $newEventName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    DatePicker("", selection: $newEventDate, displayedComponents: .date)
                        .labelsHidden()
                    
                    Button(isVI ? "Lưu" : "Save") {
                        if !newEventName.isEmpty {
                            countdownManager.addNewEvent(name: newEventName, targetDate: newEventDate)
                            isAddingNew = false
                            newEventName = ""
                        }
                    }
                    Button(isVI ? "Hủy" : "Cancel") { isAddingNew = false }
                }
                .padding(.horizontal, 16)
            } else {
                HStack {
                    Button(action: { isAddingNew = true }) {
                        Image(systemName: "plus.circle.fill")
                        Text(isVI ? "Thêm" : "Add")
                    }
                    
                    Button(action: { countdownManager.deleteSelectedEvent() }) {
                        Image(systemName: "trash.fill")
                    }.disabled(countdownManager.events.isEmpty)
                    
                    Spacer()
                    
                    Button(action: { countdownManager.cycleDisplayMode() }) {
                        Image(systemName: "menubar.arrow.up.rectangle")
                        Text(countdownManager.displayModeLabel())
                    }
                    .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    Button(action: { countdownManager.toggleLanguage() }) {
                        Image(systemName: "globe")
                        Text(isVI ? "VI" : "EN")
                    }
                    .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: {
                        NotificationManager.shared.triggerDebugNotification(manager: countdownManager)
                    }) {
                        Image(systemName: "bell.badge.fill").foregroundColor(.yellow)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
    }

    private var quoteSection: some View {
        VStack(spacing: 4) {
            Text("\u{201C}\(countdownManager.todaysQuote.text)\u{201D}")
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 20)

            Text("— \(countdownManager.todaysQuote.author)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}
