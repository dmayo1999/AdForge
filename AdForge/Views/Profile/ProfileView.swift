// ProfileView.swift
// AdForge

import SwiftUI

struct ProfileView: View {
    @Bindable var appState: AppState
    @State private var viewModel: ProfileViewModel
    @State private var showSignOutAlert = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: ProfileViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.user == nil {
                    ProgressView()
                        .tint(Design.accentLight)
                        .scaleEffect(1.4)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Profile header
                            ProfileHeaderView(user: viewModel.user)
                                .padding(Design.paddingMD)

                            // Stats row
                            if let user = viewModel.user {
                                StatsRow(user: user)
                                    .padding(.horizontal, Design.paddingMD)
                                    .padding(.bottom, Design.paddingMD)

                                // Credit balance
                                CreditBalanceLargeView(credits: user.credits)
                                    .padding(.horizontal, Design.paddingMD)
                                    .padding(.bottom, Design.paddingMD)

                                // Streak
                                StreakView(streak: user.currentStreak)
                                    .padding(.horizontal, Design.paddingMD)
                                    .padding(.bottom, Design.paddingLG)
                            }

                            // My Creations
                            VStack(alignment: .leading, spacing: Design.paddingMD) {
                                HStack {
                                    Text("My Creations")
                                        .font(Design.headlineFont)
                                        .foregroundStyle(Design.textPrimary)
                                    Spacer()
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(Design.accentLight)
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(.horizontal, Design.paddingMD)

                                if viewModel.userGenerations.isEmpty && !viewModel.isLoading {
                                    EmptyCreationsView()
                                        .padding(.horizontal, Design.paddingMD)
                                } else {
                                    LazyVGrid(columns: gridColumns, spacing: 2) {
                                        ForEach(viewModel.userGenerations) { generation in
                                            CreationThumbnail(generation: generation)
                                        }
                                    }
                                }
                            }

                            Spacer().frame(height: 100)
                        }
                    }
                    .refreshable {
                        await viewModel.loadProfile()
                        await viewModel.loadUserGenerations()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Profile")
                        .font(Design.titleFont)
                        .foregroundStyle(Design.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Design.textSecondary)
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            if viewModel.user == nil {
                await viewModel.loadProfile()
            }
            if viewModel.userGenerations.isEmpty {
                await viewModel.loadUserGenerations()
            }
        }
    }
}

// MARK: - Profile Header

private struct ProfileHeaderView: View {
    let user: AFUser?

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Design.accent, Design.accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                if let avatarURL = user?.avatarURL, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        }
                    }
                } else {
                    Text(String(user?.displayName.prefix(1) ?? "?").uppercased())
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Design.textPrimary)
                }
            }
            .shadow(color: Design.accent.opacity(0.4), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(user?.displayName ?? "Loading...")
                    .font(Design.titleFont)
                    .foregroundStyle(Design.textPrimary)
                    .lineLimit(1)

                // Level badge
                if let user = user {
                    HStack(spacing: 6) {
                        LevelBadge(level: user.level)
                        XPBar(xp: user.xp, level: user.level)
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - Level Badge

private struct LevelBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
            Text("Lv.\(level)")
                .font(Design.badgeFont)
        }
        .foregroundStyle(Design.credit)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Design.credit.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - XP Bar

private struct XPBar: View {
    let xp: Int
    let level: Int

    private var progress: Double {
        // Use the same formula as AFUser.levelProgress: 500 * level per level
        let xpForNextLevel = 500 * max(level, 1)
        return min(1.0, Double(xp % xpForNextLevel) / Double(xpForNextLevel))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Design.surfaceLight)
                    .frame(height: 6)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Design.accent, Design.accentLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 6)
            }
        }
        .frame(height: 6)
        .frame(maxWidth: 100)
    }
}

// MARK: - Stats Row

private struct StatsRow: View {
    let user: AFUser

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: user.totalGenerations, label: "Creations", icon: "wand.and.stars")
            Rectangle().fill(Design.surfaceLight).frame(width: 1, height: 40)
            StatItem(value: user.totalVotesReceived, label: "Votes", icon: "heart.fill")
            Rectangle().fill(Design.surfaceLight).frame(width: 1, height: 40)
            StatItem(value: user.totalWins, label: "Wins", icon: "trophy.fill")
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

private struct StatItem: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value.formatted())
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Design.textPrimary)
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(Design.textSecondary)
                Text(label)
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Credit Balance Large

private struct CreditBalanceLargeView: View {
    let credits: Int

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Design.credit)
                .shadow(color: Design.credit.opacity(0.4), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("Credit Balance")
                    .font(Design.captionFont)
                    .foregroundStyle(Design.textSecondary)
                Text(credits.formatted())
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Design.credit)
            }

            Spacer()

            Text("credits")
                .font(Design.captionFont)
                .foregroundStyle(Design.textSecondary)
        }
        .padding(Design.paddingMD)
        .background(
            LinearGradient(
                colors: [Design.surface, Design.credit.opacity(0.06)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .stroke(Design.credit.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Streak View

private struct StreakView: View {
    let streak: Int
    @State private var flameScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            ZStack {
                Circle()
                    .fill(Design.warning.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Design.warning, Design.error],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(flameScale)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)-day streak")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Design.textPrimary)
                Text(streak > 0 ? "Keep it going! 🔥" : "Start a streak by creating today")
                    .font(Design.captionFont)
                    .foregroundStyle(Design.textSecondary)
            }

            Spacer()
        }
        .padding(Design.paddingMD)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .stroke(streak > 0 ? Design.warning.opacity(0.4) : Design.surfaceLight, lineWidth: 1)
        )
        .onAppear {
            guard streak > 0 else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                flameScale = 1.15
            }
        }
    }
}

// MARK: - Empty Creations

private struct EmptyCreationsView: View {
    var body: some View {
        VStack(spacing: Design.paddingMD) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Design.textSecondary)
            Text("No creations yet")
                .font(Design.bodyFont)
                .foregroundStyle(Design.textSecondary)
            Text("Head to the Studio and create your first image or video!")
                .font(Design.captionFont)
                .foregroundStyle(Design.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Design.paddingXL)
    }
}

// MARK: - Creation Thumbnail

private struct CreationThumbnail: View {
    let generation: Generation

    var body: some View {
        AsyncImage(url: URL(string: generation.mediaURL)) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
            default:
                ZStack {
                    Design.surfaceLight
                    if generation.type == .video {
                        Image(systemName: "play.fill")
                            .foregroundStyle(Design.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView(appState: AppState.preview)
}
