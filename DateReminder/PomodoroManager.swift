//  PomodoroManager.swift
//  DateReminder

import SwiftUI
import Combine
import UserNotifications

enum PomodoroPhase {
    case focus, shortBreak
}

class PomodoroManager: ObservableObject {
    // ── Published state ──────────────────────────────────────────────
    @Published var phase:         PomodoroPhase = .focus
    @Published var timeRemaining: TimeInterval  = 25 * 60
    @Published var isRunning:     Bool          = false
    @Published var progress:      Double        = 1.0   // 1 = full ring, 0 = empty

    // ── Constants ────────────────────────────────────────────────────
    let focusDuration: TimeInterval = 25 * 60
    let breakDuration: TimeInterval =  5 * 60

    // ── Menu-bar label (only shown while running) ────────────────────
    var menuBarText: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d 🍅", m, s)
    }

    var phaseLabel: String {
        switch phase {
        case .focus:      return NSLocalizedString("phase_focus",      value: "Focus",       comment: "")
        case .shortBreak: return NSLocalizedString("phase_break",      value: "Short Break", comment: "")
        }
    }

    private var timer: Timer?

    // ── Controls ─────────────────────────────────────────────────────
    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.updateProgress()
                } else {
                    self.advance()
                }
            }
        }
        timer?.tolerance = 0.1
        RunLoop.main.add(timer!, forMode: .common)   // keeps firing during menu interactions
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        phase         = .focus
        timeRemaining = focusDuration
        progress      = 1.0
    }

    // ── Private ──────────────────────────────────────────────────────
    func advance() {
        timer?.invalidate()
        timer     = nil
        isRunning = false

        // Fire a local notification
        let nextPhase: PomodoroPhase = (phase == .focus) ? .shortBreak : .focus
        firePhaseNotification(completed: phase, upcoming: nextPhase)

        phase         = nextPhase
        timeRemaining = (phase == .focus) ? focusDuration : breakDuration
        updateProgress()
        start()   // auto-start next phase
    }

    private func updateProgress() {
        let total = (phase == .focus) ? focusDuration : breakDuration
        progress  = timeRemaining / total
    }

    private func firePhaseNotification(completed: PomodoroPhase, upcoming: PomodoroPhase) {
        let content        = UNMutableNotificationContent()
        content.title      = completed == .focus
            ? NSLocalizedString("notif_focus_done_title", value: "Focus session complete! 🎉", comment: "")
            : NSLocalizedString("notif_break_done_title", value: "Break's over — let's go! 💪",  comment: "")
        content.body       = upcoming  == .focus
            ? NSLocalizedString("notif_start_focus_body", value: "Time for another 25-minute sprint.", comment: "")
            : NSLocalizedString("notif_start_break_body", value: "Take a well-earned 5-minute break.",  comment: "")
        content.sound      = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)   // fire immediately
        UNUserNotificationCenter.current().add(request)
    }
}
