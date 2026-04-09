// FeedCardView.swift
// AdForge

import SwiftUI

struct FeedCardView: View {
    let generation: Generation
    let hasVoted: Bool
    let currentUser: AFUser?
    let onVote: () -> Void
    let onReport: (ReportCategory) -> Void

    @State private var showingReportSheet = false
    @State private var showingShareSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator header
            CreatorHeaderView(generation: generation)
                .padding(Design.paddingMD)

            // Media
            MediaView(generation: generation)

            // Bottom bar
            BottomBarView(
                generation: generation,
                hasVoted: hasVoted,
                heartsRemaining: currentUser?.heartsRemaining ?? 0,
                onVote: onVote,
                onShare: { showingShareSheet = true },
                onReport: { showingReportSheet = true }
            )
            .padding(.horizontal, Design.paddingMD)
            .padding(.top, Design.paddingMD)
            .padding(.bottom, Design.paddingMD)

            // Caption
            if !generation.prompt.isEmpty {
                Text(generation.prompt)
                    .font(Design.captionFont)
                    .foregroundStyle(Design.textSecondary)
                    .lineLimit(2)
                    .padding(.horizontal, Design.paddingMD)
                    .padding(.bottom, Design.paddingMD)
            }
        }
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
        .sheet(isPresented: $showingReportSheet) {
            ReportSheet { category in
                onReport(category)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(
                items: [
                    generation.mediaURL,
                    "Check out this creation on AdForge! adforge://generation/\(generation.id)"
                ]
            )
        }
    }
}

// MARK: - Creator Header

private struct CreatorHeaderView: View {
    let generation: Generation

    var body: some View {
        HStack(spacing: Design.paddingSM) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Design.accent, Design.accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Text(String(generation.userId.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Design.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(generation.userDisplayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Design.textPrimary)
                Text(generation.createdAt.timeAgoDisplay)
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
            }

            Spacer()

            // Model badge
            ModelPillBadge(model: generation.model)
        }
    }
}

// MARK: - Media View

private struct MediaView: View {
    let generation: Generation

    var body: some View {
        AsyncImage(url: URL(string: generation.type == .video
            ? (generation.thumbnailURL ?? generation.mediaURL)
            : generation.mediaURL)) { phase in
            switch phase {
            case .empty:
                ShimmerPlaceholder()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            case .success(let image):
                ZStack(alignment: .bottomTrailing) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    if generation.type == .video {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Design.textPrimary.opacity(0.9))
                            .shadow(radius: 8)
                            .padding(Design.paddingMD)
                    }
                }
            case .failure:
                ZStack {
                    Design.surfaceLight
                    Image(systemName: "photo.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(Design.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
            @unknown default:
                ShimmerPlaceholder()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .clipShape(Rectangle())
    }
}

// MARK: - Bottom Bar

private struct BottomBarView: View {
    let generation: Generation
    let hasVoted: Bool
    let heartsRemaining: Int
    let onVote: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            // Vote button + count
            VoteButton(
                voteCount: generation.voteCount,
                hasVoted: hasVoted,
                heartsRemaining: heartsRemaining,
                action: onVote
            )

            Spacer()

            // Share
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Design.textSecondary)
            }
            .buttonStyle(.plain)

            // Report overflow menu
            Menu {
                Button(role: .destructive, action: onReport) {
                    Label("Report", systemImage: "flag.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Design.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
    }
}

// MARK: - Model Pill Badge

struct ModelPillBadge: View {
    let model: AIModel

    var body: some View {
        Text(model.displayName)
            .font(Design.badgeFont)
            .foregroundStyle(Design.accentLight)
            .padding(.vertical, 4)
            .padding(.horizontal, Design.paddingSM)
            .background(Design.accent.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Date Extension

extension Date {
    var timeAgoDisplay: String {
        let seconds = Int(-timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        ScrollView {
            FeedCardView(
                generation: Generation.mock,
                hasVoted: false,
                currentUser: AFUser.mock,
                onVote: {},
                onReport: { _ in }
            )
            .padding()
        }
    }
}
