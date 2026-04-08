// CreditBalanceView.swift
// AdForge

import SwiftUI

struct CreditBalanceView: View {
    let credits: Int
    @State private var displayedCredits: Int
    @State private var animatePulse = false

    init(credits: Int) {
        self.credits = credits
        self._displayedCredits = State(initialValue: credits)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Design.credit)
                .scaleEffect(animatePulse ? 1.2 : 1.0)

            Text(displayedCredits.formatted())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Design.credit)
                .contentTransition(.numericText(countsDown: credits < displayedCredits))
        }
        .padding(.vertical, 7)
        .padding(.horizontal, Design.paddingMD)
        .background(
            Capsule()
                .fill(Design.credit.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(Design.credit.opacity(0.3), lineWidth: 1)
        )
        .onChange(of: credits) { oldValue, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                displayedCredits = newValue
                animatePulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    animatePulse = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        VStack(spacing: 20) {
            CreditBalanceView(credits: 1250)
            CreditBalanceView(credits: 0)
            CreditBalanceView(credits: 50000)
        }
    }
}
