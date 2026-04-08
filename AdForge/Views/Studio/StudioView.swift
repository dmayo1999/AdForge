// StudioView.swift
// AdForge

import SwiftUI

struct StudioView: View {
    @Bindable var appState: AppState
    @State private var viewModel: StudioViewModel

    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: StudioViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Design.paddingLG) {
                        // Type selector
                        TypeSegmentedPicker(selectedType: $viewModel.selectedType)
                            .padding(.top, Design.paddingSM)

                        // Model picker carousel
                        ModelPickerView(
                            models: viewModel.availableModels,
                            selectedModel: $viewModel.selectedModel
                        )

                        // Prompt input
                        PromptInputView(promptText: $viewModel.promptText)
                            .padding(.horizontal, Design.paddingMD)

                        // Credit cost badge
                        CreditCostBadge(cost: viewModel.creditCost, model: viewModel.selectedModel)
                            .padding(.horizontal, Design.paddingMD)

                        // Generate / Watch Ad buttons
                        VStack(spacing: Design.paddingMD) {
                            GenerateButton(
                                canGenerate: viewModel.canGenerate,
                                isGenerating: viewModel.isGenerating,
                                creditCost: viewModel.creditCost
                            ) {
                                Task { await viewModel.generate() }
                            }

                            if !viewModel.canGenerate
                                && !(viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                                WatchAdButton(
                                    isLoading: viewModel.isGenerating,
                                    adsRemaining: viewModel.adsRemainingToday
                                ) {
                                    Task { await viewModel.watchAdAndGenerate() }
                                }
                            }
                        }
                        .padding(.horizontal, Design.paddingMD)

                        // Bottom padding for tab bar
                        Spacer().frame(height: 80)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                // Generation loading overlay
                if viewModel.isGenerating {
                    GeneratingOverlay(statusText: viewModel.generationProgress ?? "Generating...")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Studio")
                        .font(Design.titleFont)
                        .foregroundStyle(Design.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    CreditBalanceView(credits: appState.currentUser?.credits ?? 0)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingResult) {
            if let generation = viewModel.lastGeneration {
                GenerationResultView(
                    generation: generation,
                    appState: appState,
                    onGenerateAnother: {
                        viewModel.showingResult = false
                        viewModel.promptText = ""
                    }
                )
            }
        }
    }
}

// MARK: - Type Segmented Picker

private struct TypeSegmentedPicker: View {
    @Binding var selectedType: GenerationType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GenerationType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedType = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type == .image ? "photo.fill" : "video.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(type == .image ? "Image" : "Video")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, Design.paddingMD)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selectedType == type ? Design.textPrimary : Design.textSecondary)
                    .background(
                        selectedType == type
                            ? Design.accent
                            : Color.clear
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Design.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Design.surfaceLight, lineWidth: 1))
        .padding(.horizontal, Design.paddingMD)
    }
}

// MARK: - Credit Cost Badge

private struct CreditCostBadge: View {
    let cost: Int
    let model: AIModel

    var body: some View {
        HStack(spacing: Design.paddingSM) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(Design.credit)
                .font(.system(size: 16))
            Text("This will cost ")
                .foregroundStyle(Design.textSecondary)
            + Text("\(cost) credits")
                .foregroundStyle(Design.credit)
                .fontWeight(.bold)
            + Text(" (\(model.displayName))")
                .foregroundStyle(Design.textSecondary)
        }
        .font(Design.captionFont)
        .padding(.vertical, Design.paddingSM)
        .padding(.horizontal, Design.paddingMD)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadiusSM)
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Generate Button

private struct GenerateButton: View {
    let canGenerate: Bool
    let isGenerating: Bool
    let creditCost: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.paddingSM) {
                if isGenerating {
                    ProgressView()
                        .tint(Design.textPrimary)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .bold))
                }
                Text(isGenerating ? "Generating..." : "Generate")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(canGenerate ? Design.textPrimary : Design.textSecondary)
            .background(
                Group {
                    if canGenerate {
                        LinearGradient(
                            colors: [Design.accent, Color(red: 0.58, green: 0.19, blue: 0.82)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Design.surfaceLight
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            .shadow(
                color: canGenerate ? Design.accent.opacity(0.45) : Color.clear,
                radius: 16, x: 0, y: 8
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .stroke(
                        canGenerate ? Color.clear : Design.surfaceLight,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate || isGenerating)
    }
}

// MARK: - Generating Overlay

private struct GeneratingOverlay: View {
    let statusText: String

    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.6
    @State private var sparkleRotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: Design.paddingLG) {
                ZStack {
                    // Pulsing rings
                    Circle()
                        .stroke(Design.accent.opacity(ringOpacity * 0.4), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale * 1.4)

                    Circle()
                        .stroke(Design.accent.opacity(ringOpacity * 0.6), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale * 1.2)

                    Circle()
                        .stroke(Design.accentLight, lineWidth: 2)
                        .frame(width: 100, height: 100)

                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Design.accent, Design.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(sparkleRotation))
                }

                Text(statusText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Design.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(Design.paddingXL)
            .background(
                RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                    .fill(Design.surface.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                            .stroke(Design.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Design.accent.opacity(0.3), radius: 30, x: 0, y: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                ringScale = 1.1
                ringOpacity = 1.0
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StudioView(appState: AppState.preview)
}
