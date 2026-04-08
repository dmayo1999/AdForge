// WatchAdButton.swift
// AdForge

import SwiftUI

struct WatchAdButton: View {
    let isLoading: Bool
    let adsRemaining: Int
    let action: () -> Void

    @State private var gradientAngle: Double = 0
    @State private var isPressed = false

    private var isDisabled: Bool { adsRemaining <= 0 || isLoading }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.paddingMD) {
                // Play icon or loading
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 40, height: 40)

                    if isLoading {
                        ProgressView()
                            .tint(Color.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: 1) // optical centering
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isLoading ? "Watching ad..." : "Watch Ad")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if isDisabled && adsRemaining <= 0 {
                        Text("0 ads remaining today")
                            .font(Design.badgeFont)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("1,000 credits")
                                .font(Design.badgeFont)
                                .foregroundStyle(.white.opacity(0.9))
                            Text("• \(adsRemaining) remaining")
                                .font(Design.badgeFont)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, Design.paddingMD)
            .frame(height: 56)
            .background(
                Group {
                    if isDisabled {
                        Design.surfaceLight
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.72, blue: 0.56),
                                Color(red: 0.05, green: 0.55, blue: 0.80)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            .shadow(
                color: isDisabled
                    ? Color.clear
                    : Color(red: 0.05, green: 0.72, blue: 0.56).opacity(0.4),
                radius: 14, x: 0, y: 6
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .stroke(
                        isDisabled ? Design.surfaceLight : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .pressEvents(
            onPress: {
                guard !isDisabled else { return }
                withAnimation(.easeIn(duration: 0.1)) { isPressed = true }
            },
            onRelease: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { isPressed = false }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        VStack(spacing: 16) {
            WatchAdButton(isLoading: false, adsRemaining: 5, action: {})
            WatchAdButton(isLoading: true, adsRemaining: 5, action: {})
            WatchAdButton(isLoading: false, adsRemaining: 0, action: {})
        }
        .padding()
    }
}
