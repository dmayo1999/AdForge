// SubDetailView.swift
// AdForge

import SwiftUI

struct SubDetailView: View {
    let sub: Sub
    @Bindable var appState: AppState

    @State private var viewModel: CompetitionsViewModel
    @State private var selectedTab: DetailTab = .entries
    @State private var showingSubmitSheet = false

    enum DetailTab: String, CaseIterable {
        case entries = "Entries"
        case leaderboard = "Leaderboard"
    }

    init(sub: Sub, appState: AppState) {
        self.sub = sub
        self.appState = appState
        self._viewModel = State(initialValue: CompetitionsViewModel(appState: appState))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Design.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header card
                SubHeaderCard(sub: sub)
                    .padding(Design.paddingMD)

                // Tab toggle
                DetailTabPicker(selectedTab: $selectedTab)
                    .padding(.horizontal, Design.paddingMD)
                    .padding(.bottom, Design.paddingMD)

                // Content
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Design.accentLight)
                        .scaleEffect(1.4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    switch selectedTab {
                    case .entries:
                        EntriesListView(
                            entries: viewModel.entries,
                            currentUser: appState.currentUser,
                            hasVotedForEntry: { viewModel.hasVotedForEntry($0) },
                            onVote: { entry in
                                Task { await viewModel.vote(for: entry) }
                            }
                        )
                    case .leaderboard:
                        LeaderboardView(entries: viewModel.leaderboard)
                    }
                }
            }

            // FAB — Submit Entry
            Button {
                showingSubmitSheet = true
            } label: {
                HStack(spacing: Design.paddingSM) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Submit Entry")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Design.textPrimary)
                .padding(.horizontal, Design.paddingLG)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Design.accent, Color(red: 0.58, green: 0.19, blue: 0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Design.accent.opacity(0.5), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, Design.paddingMD)
            .padding(.bottom, 100) // above tab bar
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(sub.name)
        .task {
            await viewModel.loadEntries(for: sub)
            await viewModel.loadLeaderboard(for: sub)
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == .leaderboard && viewModel.leaderboard.isEmpty {
                Task { await viewModel.loadLeaderboard(for: sub) }
            }
        }
        .sheet(isPresented: $showingSubmitSheet) {
            SubmitToSubSheet(
                generationId: nil,
                appState: appState,
                preselectedSub: sub,
                onSubmit: { generationId in
                    Task { await viewModel.submitEntry(generationId: generationId, to: sub) }
                }
            )
        }
    }
}

// MARK: - Sub Header Card

private struct SubHeaderCard: View {
    let sub: Sub

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            ZStack {
                Circle()
                    .fill(Design.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: sub.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Design.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sub.description)
                    .font(Design.captionFont)
                    .foregroundStyle(Design.textSecondary)
                    .lineLimit(2)

                HStack(spacing: Design.paddingSM) {
                    TimeBadge(hours: sub.votingWindowHours)
                    if sub.isActive {
                        Label("Active", systemImage: "circle.fill")
                            .font(Design.badgeFont)
                            .foregroundStyle(Design.success)
                    }
                }
            }

            Spacer()
        }
        .padding(Design.paddingMD)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
    }
}

// MARK: - Detail Tab Picker

private struct DetailTabPicker: View {
    @Binding var selectedTab: SubDetailView.DetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SubDetailView.DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selectedTab == tab ? Design.textPrimary : Design.textSecondary)
                        .background(
                            selectedTab == tab
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
    }
}

// MARK: - Entries List View

private struct EntriesListView: View {
    let entries: [CompetitionEntry]
    let currentUser: AFUser?
    let hasVotedForEntry: (String) -> Bool
    let onVote: (CompetitionEntry) -> Void

    var body: some View {
        if entries.isEmpty {
            VStack(spacing: Design.paddingMD) {
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundStyle(Design.textSecondary)
                Text("No entries yet. Be first!")
                    .font(Design.bodyFont)
                    .foregroundStyle(Design.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: Design.paddingMD) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        EntryCard(
                            entry: entry,
                            rank: index + 1,
                            heartsRemaining: currentUser?.heartsRemaining ?? 0,
                            hasVoted: hasVotedForEntry(entry.id),
                            onVote: { onVote(entry) }
                        )
                    }
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, Design.paddingMD)
            }
        }
    }
}

// MARK: - Entry Card

private struct EntryCard: View {
    let entry: CompetitionEntry
    let rank: Int
    let heartsRemaining: Int
    let hasVoted: Bool
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Rank number
            Text("#\(rank)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(rankColor)
                .frame(width: 40)

            // Thumbnail
            AsyncImage(url: URL(string: entry.mediaURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipped()
                default:
                    Design.surfaceLight
                        .frame(width: 64, height: 64)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusSM))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.userDisplayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Design.textPrimary)
                Text(entry.prompt)
                    .font(Design.captionFont)
                    .foregroundStyle(Design.textSecondary)
                    .lineLimit(2)
                ModelPillBadge(model: entry.model)
            }
            .padding(.horizontal, Design.paddingMD)

            Spacer()

            // Vote button
            VoteButton(
                voteCount: entry.voteCount,
                hasVoted: hasVoted,
                heartsRemaining: heartsRemaining,
                action: onVote
            )
            .padding(.trailing, Design.paddingMD)
        }
        .padding(.vertical, Design.paddingMD)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Design.credit
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Design.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubDetailView(sub: DefaultSubs.all[0], appState: AppState.preview)
    }
}
