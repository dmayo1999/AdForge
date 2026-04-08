// ModelPickerView.swift
// AdForge

import SwiftUI

struct ModelPickerView: View {
    let models: [AIModel]
    @Binding var selectedModel: AIModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.paddingMD) {
                Spacer().frame(width: Design.paddingSM)

                ForEach(models) { model in
                    ModelCard(
                        model: model,
                        isSelected: selectedModel == model
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedModel = model
                        }
                    }
                }

                Spacer().frame(width: Design.paddingSM)
            }
        }
    }
}

// MARK: - Model Card

private struct ModelCard: View {
    let model: AIModel
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon row
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isSelected
                                    ? Design.accent.opacity(0.2)
                                    : Design.surfaceLight
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: model.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? Design.accent : Design.textSecondary)
                    }
                    Spacer()
                    // Credit cost pill
                    CreditPill(cost: model.creditCost, isSelected: isSelected)
                }

                // Model name
                Text(model.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Design.textPrimary)
                    .lineLimit(1)

                // Short description
                Text(model.description)
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Estimated time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Design.textSecondary)
                    Text(model.estimatedTime)
                        .font(Design.badgeFont)
                        .foregroundStyle(Design.textSecondary)
                }
            }
            .padding(Design.paddingMD)
            .frame(width: 148, height: 160)
            .background(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .fill(Design.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .stroke(
                        isSelected ? Design.accent : Design.surfaceLight,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Design.accent.opacity(0.35) : Color.clear,
                radius: 12, x: 0, y: 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { withAnimation(.easeIn(duration: 0.1)) { isPressed = true } },
            onRelease: { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

// MARK: - Credit Pill

private struct CreditPill: View {
    let cost: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 9, weight: .bold))
            Text("\(cost)")
                .font(Design.badgeFont)
        }
        .foregroundStyle(isSelected ? Design.credit : Design.textSecondary)
        .padding(.vertical, 3)
        .padding(.horizontal, 7)
        .background(
            Capsule()
                .fill(isSelected ? Design.credit.opacity(0.15) : Design.surfaceLight)
        )
    }
}

// MARK: - AIModel Extension (SF Symbol icon)

extension AIModel {
    var iconName: String {
        switch self {
        case .fluxPro: return "sparkles.rectangle.stack.fill"
        case .fluxDev: return "wand.and.sparkles"
        case .wan25:   return "video.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        ModelPickerView(
            models: AIModel.allCases.filter { $0.type == .image },
            selectedModel: .constant(.fluxDev)
        )
    }
}
