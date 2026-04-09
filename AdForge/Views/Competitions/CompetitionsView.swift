// CompetitionsView.swift
// AdForge

import SwiftUI

struct CompetitionsView: View {
    @Bindable var appState: AppState
    @State private var viewModel: CompetitionsViewModel

    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: CompetitionsViewModel(appState: appState))
    }

    private let columns = [
        GridItem(.flexible(), spacing: Design.paddingMD),
        GridItem(.flexible(), spacing: Design.paddingMD)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.subs.isEmpty {
                    ProgressView()
                        .tint(Design.accentLight)
                        .scaleEffect(1.4)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Design.paddingLG) {
                            // Daily challenge spotlight
                            if let daily = viewModel.dailyChallengesSub {
                                NavigationLink(value: daily) {
                                    DailyChallengeCard(sub: daily)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, Design.paddingMD)
                            }

                            // All subs grid
                            VStack(alignment: .leading, spacing: Design.paddingMD) {
                                Text("All Competitions")
                                    .font(Design.headlineFont)
                                    .foregroundStyle(Design.textPrimary)
                                    .padding(.horizontal, Design.paddingMD)

                                LazyVGrid(columns: columns, spacing: Design.paddingMD) {
                                    ForEach(viewModel.subs) { sub in
                                        NavigationLink(value: sub) {
                                            SubCard(sub: sub)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, Design.paddingMD)
                            }

                            Spacer().frame(height: 80)
                        }
                        .padding(.top, Design.paddingSM)
                    }
                    .refreshable {
                        await viewModel.loadSubs()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Text("Competitions")
                            .font(Design.titleFont)
                            .foregroundStyle(Design.textPrimary)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Design.credit)
                    }
                }
            }
            .navigationDestination(for: Sub.self) { sub in
                SubDetailView(sub: sub, appState: appState)
            }
        }
        .task {
            if viewModel.subs.isEmpty {
                await viewModel.loadSubs()
            }
        }
    }
}

// MARK: - Daily Challenge Card

private struct DailyChallengeCard: View {
    let sub: Sub

    @State private var animateGlow = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.paddingMD) {
            HStack {
                Label("Daily Challenge", systemImage: "bolt.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Design.credit)
                    .padding(.horizontal, Design.paddingSM)
                    .padding(.vertical, 4)
                    .background(Design.credit.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
                // Time remaining badge
                TimeBadge(hours: sub.votingWindowHours)
            }

            HStack(spacing: Design.paddingMD) {
                ZStack {
                    Circle()
                        .fill(Design.accent.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: sub.iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Design.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(sub.name)
                        .font(Design.headlineFont)
                        .foregroundStyle(Design.textPrimary)
                    Text(sub.description)
                        .font(Design.captionFont)
                        .foregroundStyle(Design.textSecondary)
                        .lineLimit(2)
                }
            }

            Text("Tap to enter →")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Design.accentLight)
        }
        .padding(Design.paddingMD)
        .background(
            RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                .fill(
                    LinearGradient(
                        colors: [Design.surface, Design.accent.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                .stroke(
                    LinearGradient(
                        colors: [Design.accent.opacity(animateGlow ? 0.8 : 0.4), Design.accentLight.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Design.accent.opacity(animateGlow ? 0.25 : 0.1), radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
}

// MARK: - Sub Card

private struct SubCard: View {
    let sub: Sub

    private let accentColors: [Color] = [
        Design.accent, Design.heart, Design.success,
        Design.warning, Color(red: 0.3, green: 0.7, blue: 1.0),
        Color(red: 0.9, green: 0.4, blue: 0.3)
    ]

    private var cardColor: Color {
        let hash = abs(sub.id.hashValue) % accentColors.count
        return accentColors[hash]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent color strip at top
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [cardColor, cardColor.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: Design.cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: Design.cornerRadius
                    )
                )

            VStack(alignment: .leading, spacing: Design.paddingSM) {
                HStack {
                    Image(systemName: sub.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(cardColor)
                    Spacer()
                    // Entry count badge
                    Text("Live")
                        .font(Design.badgeFont)
                        .foregroundStyle(Design.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Design.success.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(sub.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Design.textPrimary)
                    .lineLimit(2)

                Text(sub.description)
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
                    .lineLimit(2)

                Spacer()

                // Types accepted + voting window
                HStack(spacing: 4) {
                    ForEach(sub.acceptedTypes, id: \.self) { type in
                        Image(systemName: type == .image ? "photo.fill" : "video.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Design.textSecondary)
                    }
                    Spacer()
                    TimeBadge(hours: sub.votingWindowHours)
                }
            }
            .padding(Design.paddingMD)
        }
        .frame(height: 172)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
    }
}

// MARK: - Time Badge

struct TimeBadge: View {
    let hours: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.fill")
                .font(.system(size: 9))
            Text("Ends in \(hours)h")
                .font(Design.badgeFont)
        }
        .foregroundStyle(Design.warning)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Design.warning.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    CompetitionsView(appState: AppState.preview)
}
