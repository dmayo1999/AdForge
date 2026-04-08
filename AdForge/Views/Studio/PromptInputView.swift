// PromptInputView.swift
// AdForge

import SwiftUI

struct PromptInputView: View {
    @Binding var promptText: String

    private let maxCharacters = 500

    private let suggestions = [
        "cyberpunk city at night",
        "anime portrait",
        "underwater world",
        "neon forest",
        "retro sci-fi robot",
        "mythical creature",
        "dreamlike sunset",
        "hyper-detailed macro shot"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Design.paddingSM) {
            // Text editor
            ZStack(alignment: .topLeading) {
                // Placeholder
                if promptText.isEmpty {
                    Text("Describe what you want to create...")
                        .font(Design.bodyFont)
                        .foregroundStyle(Design.textSecondary.opacity(0.7))
                        .padding(.horizontal, Design.paddingMD)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $promptText)
                    .font(Design.bodyFont)
                    .foregroundStyle(Design.textPrimary)
                    .tint(Design.accentLight)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(.horizontal, Design.paddingMD - 5) // TextEditor has built-in padding
                    .padding(.vertical, 8)
                    .onChange(of: promptText) { _, newValue in
                        if newValue.count > maxCharacters {
                            promptText = String(newValue.prefix(maxCharacters))
                        }
                    }
            }
            .background(Design.surface)
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .stroke(
                        promptText.isEmpty ? Design.surfaceLight : Design.accent.opacity(0.5),
                        lineWidth: 1
                    )
            )

            // Character count
            HStack {
                Spacer()
                Text("\(promptText.count)/\(maxCharacters)")
                    .font(Design.badgeFont)
                    .foregroundStyle(
                        promptText.count > Int(Double(maxCharacters) * 0.9)
                            ? Design.warning
                            : Design.textSecondary
                    )
            }
            .padding(.horizontal, Design.paddingSM)

            // Suggestion chips
            Text("Quick prompts")
                .font(Design.captionFont)
                .foregroundStyle(Design.textSecondary)
                .padding(.horizontal, Design.paddingSM)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.paddingSM) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        SuggestionChip(text: suggestion) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                if promptText.isEmpty {
                                    promptText = suggestion
                                } else {
                                    promptText = promptText
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    promptText += ", " + suggestion
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Design.paddingSM)
            }
        }
    }
}

// MARK: - Suggestion Chip

private struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Design.captionFont)
                .foregroundStyle(Design.accentLight)
                .padding(.vertical, 7)
                .padding(.horizontal, Design.paddingMD)
                .background(Design.accent.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Design.accent.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { withAnimation(.easeIn(duration: 0.1)) { isPressed = true } },
            onRelease: { withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        PromptInputView(promptText: .constant(""))
            .padding()
    }
}
