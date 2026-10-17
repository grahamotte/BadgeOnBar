import Combine
import SwiftUI

struct AppView: View {
    @StateObject private var timer = FocusTimer()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                if geometry.size.width > geometry.size.height {
                    landscapeContent(in: geometry.size)
                } else {
                    portraitContent(in: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onReceive(ticker) { _ in timer.tick() }
    }

    private func portraitContent(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 12)
            timerView(size: timerSize(in: size))
            Spacer(minLength: 18)
            sessionPicker
            Spacer(minLength: 14)
            controls
            Spacer(minLength: 16)
            footer
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 34)
        .frame(maxWidth: 520, maxHeight: .infinity)
    }

    private func landscapeContent(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)

            HStack(spacing: 44) {
                timerView(size: min(size.height - 98, size.width * 0.34, 330))

                VStack(spacing: 16) {
                    sessionPicker
                    controls
                    footer
                }
                .frame(maxWidth: 360)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 18)
        .frame(maxWidth: 900, maxHeight: .infinity)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.03, blue: 0.10), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.45, green: 0.18, blue: 1).opacity(0.32))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .offset(x: 170, y: -260)

            Circle()
                .fill(Color(red: 1, green: 0.26, blue: 0.48).opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 110)
                .offset(x: -190, y: 300)

            LinearGradient(
                colors: [.white.opacity(0.06), .clear, .white.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .frame(width: 28, height: 28)
                    .background(.white, in: Circle())

                Text("CODE MOTO")
                    .font(.caption.bold())
                    .tracking(1.8)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: .green, radius: 5)
                Text("IN THE ZONE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
            }
            .foregroundStyle(.white.opacity(0.62))
        }
    }

    private func timerView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.035))
                .overlay(Circle().stroke(.white.opacity(0.08)))

            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 12)
                .padding(11)

            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 1, green: 0.30, blue: 0.48),
                            Color(red: 0.64, green: 0.28, blue: 1),
                            Color(red: 0.27, green: 0.78, blue: 1),
                            Color(red: 1, green: 0.30, blue: 0.48),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .padding(11)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.purple.opacity(0.65), radius: 12)
                .animation(.smooth, value: timer.progress)

            VStack(spacing: 8) {
                Text(timer.isRunning ? "DEEP FOCUS" : "READY")
                    .font(.caption2.bold())
                    .tracking(2.5)
                    .foregroundStyle(.white.opacity(0.5))

                Text(timer.timeText)
                    .font(.system(size: size * 0.22, weight: .light, design: .rounded))
                    .tracking(-2)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)

                Text("Make something remarkable")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(32)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time remaining, \(timer.timeText)")
    }

    private var sessionPicker: some View {
        HStack(spacing: 4) {
            sessionButton(minutes: 25, label: "SPRINT")
            sessionButton(minutes: 50, label: "DEEP")
        }
        .padding(4)
        .background(.white.opacity(0.07), in: Capsule())
        .frame(maxWidth: 330)
    }

    private func sessionButton(minutes: Int, label: String) -> some View {
        Button {
            timer.select(minutes)
        } label: {
            HStack(spacing: 7) {
                Text(label)
                    .font(.caption2.bold())
                    .tracking(1.2)
                Text("\(minutes) MIN")
                    .font(.caption2)
                    .foregroundStyle(timer.minutes == minutes ? .black.opacity(0.55) : .white.opacity(0.35))
            }
            .foregroundStyle(timer.minutes == minutes ? .black : .white.opacity(0.65))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(timer.minutes == minutes ? Color.white : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(timer.isRunning)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                timer.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.08), in: Circle())
            }

            Button {
                timer.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    Text(timer.isRunning ? "PAUSE SESSION" : "START SESSION")
                        .font(.caption.bold())
                        .tracking(1.4)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.white, in: Capsule())
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 330)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            stat(value: "\(timer.completedSessions)", label: "SESSIONS")
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 28)
            stat(value: "\(timer.completedSessions * timer.minutes)m", label: "FOCUS")
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 28)
            stat(value: timer.completedSessions > 0 ? "ON" : "NEW", label: "MOMENTUM")
        }
        .frame(maxWidth: 360)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    private func timerSize(in size: CGSize) -> CGFloat {
        min(size.width - 64, size.height * 0.36, 330)
    }
}
