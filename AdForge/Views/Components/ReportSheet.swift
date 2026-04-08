// ReportSheet.swift
// AdForge

import SwiftUI

struct ReportSheet: View {
    let onReport: (ReportCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ReportCategory? = nil
    @State private var otherText: String = ""
    @State private var isSubmitting = false

    var canSubmit: Bool {
        guard let cat = selectedCategory else { return false }
        if cat == .other { return !otherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Design.paddingLG) {
                        // Header
                        VStack(alignment: .leading, spacing: Design.paddingSM) {
                            Text("What's the issue?")
                                .font(Design.headlineFont)
                                .foregroundStyle(Design.textPrimary)
                            Text("Your report helps keep AdForge safe. All reports are anonymous.")
                                .font(Design.captionFont)
                                .foregroundStyle(Design.textSecondary)
                        }
                        .padding(.horizontal, Design.paddingMD)

                        // Category rows
                        VStack(spacing: Design.paddingSM) {
                            ForEach(ReportCategory.allCases, id: \.self) { category in
                                ReportCategoryRow(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Design.paddingMD)

                        // Additional details for "other"
                        if selectedCategory == .other {
                            VStack(alignment: .leading, spacing: Design.paddingSM) {
                                Text("Additional details")
                                    .font(Design.captionFont)
                                    .foregroundStyle(Design.textSecondary)
                                    .padding(.horizontal, Design.paddingMD)

                                ZStack(alignment: .topLeading) {
                                    if otherText.isEmpty {
                                        Text("Describe the issue...")
                                            .font(Design.bodyFont)
                                            .foregroundStyle(Design.textSecondary.opacity(0.6))
                                            .padding(.horizontal, Design.paddingMD)
                                            .padding(.vertical, 14)
                                            .allowsHitTesting(false)
                                    }

                                    TextEditor(text: $otherText)
                                        .font(Design.bodyFont)
                                        .foregroundStyle(Design.textPrimary)
                                        .tint(Design.accentLight)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .frame(minHeight: 100)
                                        .padding(.horizontal, Design.paddingMD - 5)
                                        .padding(.vertical, 8)
                                }
                                .background(Design.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Design.cornerRadius)
                                        .stroke(Design.accent.opacity(0.4), lineWidth: 1)
                                )
                                .padding(.horizontal, Design.paddingMD)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }

                        // Submit button
                        Button {
                            guard let category = selectedCategory else { return }
                            isSubmitting = true
                            onReport(category)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: Design.paddingSM) {
                                if isSubmitting {
                                    ProgressView().tint(.white).scaleEffect(0.85)
                                } else {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                Text(isSubmitting ? "Reporting..." : "Submit Report")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle(canSubmit ? .white : Design.textSecondary)
                            .background(canSubmit ? Design.error : Design.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: Design.cornerRadius)
                                    .stroke(canSubmit ? Color.clear : Design.surfaceLight, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit || isSubmitting)
                        .padding(.horizontal, Design.paddingMD)

                        Spacer().frame(height: 32)
                    }
                    .padding(.top, Design.paddingMD)
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Design.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Report Category Row

private struct ReportCategoryRow: View {
    let category: ReportCategory
    let isSelected: Bool
    let action: () -> Void

    private var title: String {
        switch category {
        case .offensive: return "Offensive or harmful"
        case .spam:      return "Spam or irrelevant"
        case .deepfake:  return "Deepfake or impersonation"
        case .other:     return "Something else"
        }
    }

    private var icon: String {
        switch category {
        case .offensive: return "exclamationmark.triangle.fill"
        case .spam:      return "xmark.octagon.fill"
        case .deepfake:  return "person.slash.fill"
        case .other:     return "questionmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch category {
        case .offensive: return Design.error
        case .spam:      return Design.warning
        case .deepfake:  return Design.heart
        case .other:     return Design.textSecondary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.paddingMD) {
                ZStack {
                    Circle()
                        .fill(isSelected ? iconColor.opacity(0.15) : Design.surfaceLight)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? iconColor : Design.textSecondary)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Design.textPrimary)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Design.accent : Design.surfaceLight, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Design.accent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(Design.paddingMD)
            .background(Design.surface)
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .stroke(isSelected ? Design.accent.opacity(0.5) : Design.surfaceLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReportSheet { _ in }
}
