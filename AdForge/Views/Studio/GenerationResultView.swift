// GenerationResultView.swift
// AdForge

import SwiftUI
import AVKit

struct GenerationResultView: View {
    let generation: Generation
    @Bindable var appState: AppState
    let onGenerateAnother: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingSubmitSheet = false
    @State private var saveSuccess = false
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Media display
                        MediaDisplayView(generation: generation)
                            .padding(.bottom, Design.paddingMD)

                        // Metadata card
                        VStack(alignment: .leading, spacing: Design.paddingMD) {
                            // Prompt
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Prompt", systemImage: "quote.bubble.fill")
                                    .font(Design.captionFont)
                                    .foregroundStyle(Design.textSecondary)
                                Text(generation.prompt)
                                    .font(Design.bodyFont)
                                    .foregroundStyle(Design.textPrimary)
                            }

                            Divider()
                                .background(Design.surfaceLight)

                            // Model + cost row
                            HStack {
                                ModelBadge(model: generation.model)
                                Spacer()
                                HStack(spacing: 5) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(Design.credit)
                                    Text("\(generation.creditCost) credits")
                                        .font(Design.captionFont)
                                        .foregroundStyle(Design.textSecondary)
                                }
                            }
                        }
                        .padding(Design.paddingMD)
                        .background(Design.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Design.cornerRadius)
                                .stroke(Design.surfaceLight, lineWidth: 1)
                        )
                        .padding(.horizontal, Design.paddingMD)

                        // Action buttons
                        VStack(spacing: Design.paddingMD) {
                            // Primary actions row
                            HStack(spacing: Design.paddingMD) {
                                ActionButton(
                                    icon: "square.and.arrow.down.fill",
                                    label: saveSuccess ? "Saved!" : "Save",
                                    color: saveSuccess ? Design.success : Design.accentLight,
                                    action: saveToPhotos
                                )

                                ActionButton(
                                    icon: "square.and.arrow.up.fill",
                                    label: "Share",
                                    color: Design.accentLight,
                                    action: { showingShareSheet = true }
                                )

                                ActionButton(
                                    icon: "trophy.fill",
                                    label: "Submit",
                                    color: Design.credit,
                                    action: { showingSubmitSheet = true }
                                )
                            }
                            .padding(.horizontal, Design.paddingMD)

                            // Generate Another
                            Button {
                                dismiss()
                                onGenerateAnother()
                            } label: {
                                HStack(spacing: Design.paddingSM) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Generate Another")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundStyle(Design.textPrimary)
                                .background(Design.surfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Design.cornerRadius)
                                        .stroke(Design.surfaceLight, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Design.paddingMD)
                        }
                        .padding(.top, Design.paddingMD)

                        if let error = saveError {
                            Text(error)
                                .font(Design.captionFont)
                                .foregroundStyle(Design.error)
                                .padding(Design.paddingMD)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Result")
                        .font(Design.headlineFont)
                        .foregroundStyle(Design.textPrimary)
                }
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(
                items: [generation.mediaURL, "Check out what I made with AdForge! adforge://generation/\(generation.id)"]
            )
        }
        .sheet(isPresented: $showingSubmitSheet) {
            SubmitToSubSheet(
                generationId: generation.id,
                appState: appState
            )
        }
    }

    private func saveToPhotos() {
        guard let url = URL(string: generation.mediaURL) else { return }
        Task {
            do {
                if generation.type == .image {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                }
                withAnimation { saveSuccess = true }
                try? await Task.sleep(for: .seconds(2))
                withAnimation { saveSuccess = false }
            } catch {
                saveError = "Could not save to Photos."
            }
        }
    }
}

// MARK: - Media Display View

private struct MediaDisplayView: View {
    let generation: Generation

    var body: some View {
        Group {
            if generation.type == .image {
                AsyncImage(url: URL(string: generation.mediaURL)) { phase in
                    switch phase {
                    case .empty:
                        ShimmerPlaceholder()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                            .shadow(color: Design.accent.opacity(0.2), radius: 20, x: 0, y: 10)
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: Design.cornerRadius)
                                .fill(Design.surfaceLight)
                            Image(systemName: "photo.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(Design.textSecondary)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    @unknown default:
                        ShimmerPlaceholder()
                    }
                }
            } else {
                VideoPlayerView(videoURL: URL(string: generation.mediaURL))
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
            }
        }
        .padding(.horizontal, Design.paddingMD)
    }
}

// MARK: - Video Player View

private struct VideoPlayerView: View {
    let videoURL: URL?

    var body: some View {
        ZStack {
            if let url = videoURL {
                let player = AVPlayer(url: url)
                VideoPlayer(player: player)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: Design.cornerRadius)
                        .fill(Design.surfaceLight)
                    Image(systemName: "video.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(Design.textSecondary)
                }
            }
        }
    }
}

// MARK: - Model Badge

private struct ModelBadge: View {
    let model: AIModel

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: model.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(model.displayName)
                .font(Design.badgeFont)
        }
        .foregroundStyle(Design.accentLight)
        .padding(.vertical, 4)
        .padding(.horizontal, Design.paddingSM)
        .background(Design.accent.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { withAnimation(.easeIn(duration: 0.1)) { isPressed = true } },
            onRelease: { withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

// MARK: - Shimmer Placeholder

struct ShimmerPlaceholder: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: Design.cornerRadius)
                    .fill(Design.surface)
                LinearGradient(
                    colors: [
                        Color.clear,
                        Design.surfaceLight.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 80)
                .offset(x: shimmerOffset)
                .mask(
                    RoundedRectangle(cornerRadius: Design.cornerRadius)
                        .fill(Color.white)
                )
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = geo.size.width + 200
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Preview

#Preview {
    GenerationResultView(
        generation: Generation.mock,
        appState: AppState.preview,
        onGenerateAnother: {}
    )
}
