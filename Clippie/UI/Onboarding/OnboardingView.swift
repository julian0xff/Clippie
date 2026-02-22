import KeyboardShortcuts
import SwiftUI

struct OnboardingView: View {
    let settingsStore: SettingsStore
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    hotkeyStep
                case 2:
                    readyStep
                default:
                    EmptyView()
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.borderless)
                }

                Spacer()

                if currentStep < 2 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        settingsStore.hasCompletedOnboarding = true
                        NSApp.keyWindow?.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .frame(width: 460, height: 520)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "paperclip.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Welcome to Clippie")
                .font(.largeTitle.bold())

            Text("Your clipboard history, organized and searchable.\nClippie captures everything you copy — text, images,\nand file references — and keeps it all at your fingertips.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 40)
    }

    private var hotkeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Set Your Hotkey")
                .font(.title.bold())

            Text("Press a keyboard shortcut to quickly\ntoggle the history window from anywhere.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            KeyboardShortcuts.Recorder("", name: .toggleHistoryWindow)
                .padding(.top, 8)

            Text("Default: ⌘⇧V")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 40)
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "doc.on.clipboard", text: "Copy anything — it's automatically saved")
                featureRow(icon: "magnifyingglass", text: "Search your clipboard history instantly")
                featureRow(icon: "clock.arrow.circlepath", text: "Browse history organized by day")
                featureRow(icon: "square.and.arrow.up", text: "Export any day's clips as markdown")
            }
            .padding(.top, 8)

            Text("Look for the paperclip icon in your menu bar.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }
}
