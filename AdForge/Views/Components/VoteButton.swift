// VoteButton.swift
// AdForge

import SwiftUI

struct VoteButton: View {
    let voteCount: Int
    let hasVoted: Bool
    let heartsRemaining: Int
    let action: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var particleOpacity: Double = 0
    @State private var particleOffset: CGFloat = 0

    private var isDisabled: Bool { heartsRemaining <= 0 && !hasVoted }

    var body: some View {
        Button {
            guard !isDisabled else { return }
            triggerHeartAnimation()
            action()
        } label: {
            HStack(spacing: 5) {
                ZStack {
                    // Burst particle effect when voting
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Design.heart.opacity(particleOpacity))
                        .scaleEffect(1.6)
                        .offset(y: -particleOffset)

                    // Main heart icon
                    Image(systemName: hasVoted ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            hasVoted ? Design.heart : (isDisabled ? Design.textSecondary.opacity(0.5) : Design.textSecondary)
                        )
                        .scaleEffect(scale)
                }
                .frame(width: 28, height: 28)

                Text(voteCount.compactFormatted)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        hasVoted ? Design.heart : Design.textSecondary
                    )
                    .contentTransition(.numericText(countsDown: false))
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func triggerHeartAnimation() {
        // Bounce scale
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
            scale = 1.35
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6).delay(0.15)) {
            scale = 1.0
        }

        // Particle burst
        withAnimation(.easeOut(duration: 0.4)) {
            particleOpacity = 0.8
            particleOffset = 18
        }
        withAnimation(.easeIn(duration: 0.25).delay(0.3)) {
            particleOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particleOffset = 0
        }
    }
}

// MARK: - Compact number formatter

extension Int {
    var compactFormatted: String {
        switch self {
        case ..<1000:
            return "\(self)"
        case 1000..<1_000_000:
            let k = Double(self) / 1000.0
            if k.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(k))k"
            }
            return String(format: "%.1fk", k)
        default:
            let m = Double(self) / 1_000_000.0
            return String(format: "%.1fM", m)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        VStack(spacing: 24) {
            HStack(spacing: 32) {
                VoteButton(voteCount: 0, hasVoted: false, heartsRemaining: 10, action: {})
                VoteButton(voteCount: 42, hasVoted: false, heartsRemaining: 10, action: {})
                VoteButton(voteCount: 1337, hasVoted: true, heartsRemaining: 10, action: {})
                VoteButton(voteCount: 50000, hasVoted: false, heartsRemaining: 0, action: {})
            }
        }
        .padding()
    }
}
