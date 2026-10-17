//
//  PomodoroView.swift
//  DateReminder
//
//  Created by Hodaka on 7/4/26.
//


//  PomodoroView.swift
//  DateReminder

import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var pomodoroManager: PomodoroManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            phaseLabel
            ringTimer
            timeLabel
            controlButtons

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ── Phase label ──────────────────────────────────────────────────
    private var phaseLabel: some View {
        Text(pomodoroManager.phaseLabel.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.5))
            .tracking(3)
    }

    // ── Circular ring ────────────────────────────────────────────────
    private var ringTimer: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 10)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(pomodoroManager.progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: ringColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle:   .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: pomodoroManager.progress)

            // Glow dot at the tip
            tipDot
        }
        .frame(width: 160, height: 160)
    }

    private var ringColors: [Color] {
        pomodoroManager.phase == .focus
            ? [Color(red:0.45, green:0.65, blue:1), Color(red:0.75, green:0.45, blue:1)]
            : [Color(red:0.3,  green:0.9,  blue:0.6), Color(red:0.1,  green:0.7,  blue:0.5)]
    }

    private var tipDot: some View {
        GeometryReader { geo in
            let center  = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius  = geo.size.width / 2 - 5
            let angle   = 2 * Double.pi * pomodoroManager.progress - Double.pi / 2
            let dotX    = center.x + CGFloat(cos(angle)) * radius
            let dotY    = center.y + CGFloat(sin(angle)) * radius

            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .shadow(color: .white.opacity(0.8), radius: 4)
                .position(x: dotX, y: dotY)
                .animation(.linear(duration: 1), value: pomodoroManager.progress)
        }
    }

    // ── MM:SS label ──────────────────────────────────────────────────
    private var timeLabel: some View {
        let m = Int(pomodoroManager.timeRemaining) / 60
        let s = Int(pomodoroManager.timeRemaining) % 60
        return Text(String(format: "%02d:%02d", m, s))
            .font(.system(size: 38, weight: .thin, design: .monospaced))
            .foregroundColor(.white)
            .monospacedDigit()
    }

    // ── Play / Pause / Reset ─────────────────────────────────────────
    private var controlButtons: some View {
        HStack(spacing: 28) {
            // Reset
            controlButton(icon: "arrow.counterclockwise", size: 18) {
                pomodoroManager.reset()
            }

            // Play / Pause (larger, prominent)
            controlButton(
                icon: pomodoroManager.isRunning ? "pause.fill" : "play.fill",
                size: 26,
                background: true
            ) {
                pomodoroManager.isRunning ? pomodoroManager.pause() : pomodoroManager.start()
            }

            // Skip to next phase
            controlButton(icon: "forward.end.fill", size: 18) {
                pomodoroManager.advance()
            }
        }
    }

    @ViewBuilder
    private func controlButton(
        icon: String,
        size: CGFloat,
        background: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                if background {
                    Circle()
                        .fill(
                            LinearGradient(colors: ringColors,
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: ringColors.first?.opacity(0.5) ?? .clear, radius: 8)
                }
                Image(systemName: icon)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}