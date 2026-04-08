// SubmitToSubSheet.swift
// AdForge

import SwiftUI

struct SubmitToSubSheet: View {
    let generationId: String?
    @Bindable var appState: AppState
    var preselectedSub: Sub? = nil
    var onSubmit: ((String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGenerationId: String? = nil
    @State private var selectedSub: Sub? = nil
    @State private var recentGenerations: [Generation] = []
    @State private var availableSubs: [Sub] = DefaultSubs.all
    @State private var isSubmitting = false
    @State private var isLoadingGenerations = false

    private let generationColumns = [
        GridItem(.flexible(), spacing: Design.paddingSM),
        GridItem(.flexible(), spacing: Design.paddingSM),
        GridItem(.flexible(), spacing: Design.paddingSM)
    ]

    var canSubmit: Bool {
        selectedGenerationId != nil && selectedSub != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Design.paddingLG) {
                        // Generation picker (skip if generationId provided)
                        if generationId == nil {
                            VStack(alignment: .leading, spacing: Design.paddingMD) {
                                Label("Pick a Creation", systemImage: "photo.stack.fill")
                                    .font(Design.headlineFont)
                                    .foregroundStyle(Design.textPrimary)

                                if isLoadingGenerations {
                                    ProgressView()
                                        .tint(Design.accentLight)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else if recentGenerations.isEmpty {
                                    VStack(spacing: Design.paddingMD) {
                                        Image(systemName: "tray.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(Design.textSecondary)
                                        Text("No creations yet. Go to Studio first!")
                                            .font(Design.captionFont)
                                            .foregroundStyle(Design.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(Design.paddingXL)
                                } else {
                                    LazyVGrid(columns: generationColumns, spacing: Design.paddingSM) {
                                        ForEach(recentGenerations) { gen in
                                            GenerationThumbnail(
                                                generation: gen,
                                                isSelected: selectedGenerationId == gen.id
                                            ) {
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                    selectedGenerationId = gen.id
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Design.paddingMD)
                        } else {
                            // Show confirmation of selected generation
                            SelectedGenerationConfirmation(generationId: generationId!)
                                .padding(.horizontal, Design.paddingMD)
                        }

                        // Sub picker (skip if preselected)
                        if preselectedSub == nil {
                            VStack(alignment: .leading, spacing: Design.paddingMD) {
                                Label("Choose a Competition", systemImage: "trophy.fill")
                                    .font(Design.headlineFont)
                                    .foregroundStyle(Design.textPrimary)
                                    .padding(.horizontal, Design.paddingMD)

                                VStack(spacing: Design.paddingSM) {
                                    ForEach(availableSubs.filter { $0.isActive }) { sub in
                                        SubPickerRow(
                                            sub: sub,
                                            isSelected: selectedSub?.id == sub.id
                                        ) {
                                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                selectedSub = sub
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, Design.paddingMD)
                            }
                        } else {
                            // Show preselected sub info
                            VStack(alignment: .leading, spacing: Design.paddingSM) {
                                Label("Submitting to", systemImage: "trophy.fill")
                                    .font(Design.captionFont)
                                    .foregroundStyle(Design.textSecondary)
                                    .padding(.horizontal, Design.paddingMD)

                                SubPickerRow(sub: preselectedSub!, isSelected: true, action: {})
                                    .padding(.horizontal, Design.paddingMD)
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, Design.paddingMD)
                }

                // Confirm button pinned at bottom
                VStack {
                    Spacer()
                    ConfirmButton(
                        canSubmit: canSubmit,
                        isSubmitting: isSubmitting,
                        action: submitEntry
                    )
                    .padding(.horizontal, Design.paddingMD)
                    .padding(.bottom, 32)
                    .background(
                        LinearGradient(
                            colors: [Design.background.opacity(0), Design.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
                }
            }
            .navigationTitle("Submit Entry")
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
        .onAppear {
            setupInitialState()
            Task { await loadRecentGenerations() }
        }
    }

    private func setupInitialState() {
        if let preselected = preselectedSub {
            selectedSub = preselected
        }
        if let genId = generationId {
            selectedGenerationId = genId
        }
    }

    private func loadRecentGenerations() async {
        guard generationId == nil else { return }
        isLoadingGenerations = true
        do {
            let all = try await appState.feedService.fetchFeed(page: 0)
            recentGenerations = all.filter { $0.userId == appState.currentUser?.id }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
        isLoadingGenerations = false
    }

    private func submitEntry() {
        guard let genId = selectedGenerationId ?? generationId,
              let sub = selectedSub else { return }
        isSubmitting = true
        Task {
            do {
                try await appState.competitionService.submitEntry(
                    generationId: genId,
                    subId: sub.id
                )
                onSubmit?(genId)
                dismiss()
            } catch {
                appState.errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - Generation Thumbnail

private struct GenerationThumbnail: View {
    let generation: Generation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: generation.mediaURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Design.surfaceLight
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusSM))
                .overlay(
                    RoundedRectangle(cornerRadius: Design.cornerRadiusSM)
                        .stroke(
                            isSelected ? Design.accent : Color.clear,
                            lineWidth: 2.5
                        )
                )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Design.accent)
                        .background(Circle().fill(Color.white).padding(2))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Generation Confirmation

private struct SelectedGenerationConfirmation: View {
    let generationId: String

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Design.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("Creation selected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Design.textPrimary)
                Text("ID: \(String(generationId.prefix(16)))...")
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
            }

            Spacer()
        }
        .padding(Design.paddingMD)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .stroke(Design.success.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Sub Picker Row

private struct SubPickerRow: View {
    let sub: Sub
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.paddingMD) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Design.accent.opacity(0.2) : Design.surfaceLight)
                        .frame(width: 40, height: 40)
                    Image(systemName: sub.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Design.accent : Design.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Design.textPrimary)
                    HStack(spacing: 4) {
                        TimeBadge(hours: sub.votingWindowHours)
                        ForEach(sub.acceptedTypes, id: \.self) { type in
                            Image(systemName: type == .image ? "photo.fill" : "video.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Design.textSecondary)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Design.accent)
                }
            }
            .padding(Design.paddingMD)
            .background(Design.surface)
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .stroke(
                        isSelected ? Design.accent : Design.surfaceLight,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confirm Button

private struct ConfirmButton: View {
    let canSubmit: Bool
    let isSubmitting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.paddingSM) {
                if isSubmitting {
                    ProgressView().tint(Design.textPrimary).scaleEffect(0.85)
                } else {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                Text(isSubmitting ? "Submitting..." : "Submit Entry")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(canSubmit ? Design.textPrimary : Design.textSecondary)
            .background(
                canSubmit
                    ? LinearGradient(
                        colors: [Design.accent, Color(red: 0.58, green: 0.19, blue: 0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ).eraseToAnyShapeStyle()
                    : Design.surfaceLight.eraseToAnyShapeStyle()
            )
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            .shadow(
                color: canSubmit ? Design.accent.opacity(0.4) : Color.clear,
                radius: 16, x: 0, y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSubmitting)
    }
}

// MARK: - ShapeStyle extension

extension ShapeStyle where Self == AnyShapeStyle {
    static func eraseToAnyShapeStyle<S: ShapeStyle>(_ style: S) -> AnyShapeStyle {
        AnyShapeStyle(style)
    }
}

extension ShapeStyle {
    func eraseToAnyShapeStyle() -> AnyShapeStyle {
        AnyShapeStyle(self)
    }
}

// MARK: - Preview

#Preview {
    SubmitToSubSheet(generationId: nil, appState: AppState.preview)
}
