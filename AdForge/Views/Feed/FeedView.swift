// FeedView.swift
// AdForge

import SwiftUI

struct FeedView: View {
    @Bindable var appState: AppState
    @State private var viewModel: FeedViewModel

    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: FeedViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Design.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.generations.isEmpty {
                    LoadingFeedView()
                } else if viewModel.generations.isEmpty {
                    EmptyFeedView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Design.paddingMD) {
                            ForEach(viewModel.generations) { generation in
                                FeedCardView(
                                    generation: generation,
                                    hasVoted: viewModel.hasVoted(for: generation),
                                    currentUser: appState.currentUser,
                                    onVote: {
                                        Task { await viewModel.vote(for: generation) }
                                    },
                                    onReport: { category in
                                        Task { await viewModel.report(generation: generation, category: category) }
                                    }
                                )
                                .onAppear {
                                    // Load more when near the end
                                    if generation.id == viewModel.generations.last?.id {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                            }

                            if viewModel.isLoadingMore {
                                HStack {
                                    ProgressView()
                                        .tint(Design.accentLight)
                                    Text("Loading more...")
                                        .font(Design.captionFont)
                                        .foregroundStyle(Design.textSecondary)
                                }
                                .padding(Design.paddingMD)
                            }

                            // Bottom padding for tab bar
                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, Design.paddingMD)
                        .padding(.top, Design.paddingSM)
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Text("Feed")
                            .font(Design.titleFont)
                            .foregroundStyle(Design.textPrimary)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Design.warning)
                    }
                }
            }
        }
        .task {
            if viewModel.generations.isEmpty {
                await viewModel.loadFeed()
            }
        }
    }
}

// MARK: - Loading Feed View

private struct LoadingFeedView: View {
    var body: some View {
        VStack(spacing: Design.paddingMD) {
            ForEach(0..<3, id: \.self) { _ in
                FeedCardSkeleton()
            }
        }
        .padding(.horizontal, Design.paddingMD)
        .padding(.top, Design.paddingSM)
    }
}

private struct FeedCardSkeleton: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(alignment: .leading, spacing: Design.paddingMD) {
            // Header skeleton
            HStack(spacing: Design.paddingSM) {
                Circle()
                    .fill(Design.surfaceLight)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Capsule().fill(Design.surfaceLight).frame(width: 100, height: 12)
                    Capsule().fill(Design.surfaceLight).frame(width: 60, height: 10)
                }
                Spacer()
            }
            // Image skeleton
            RoundedRectangle(cornerRadius: Design.cornerRadius)
                .fill(Design.surfaceLight)
                .aspectRatio(1, contentMode: .fit)
            // Caption skeleton
            Capsule().fill(Design.surfaceLight).frame(height: 12)
            Capsule().fill(Design.surfaceLight).frame(width: 200, height: 12)
        }
        .padding(Design.paddingMD)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusXL))
        .overlay(shimmer)
    }

    private var shimmer: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [Color.clear, Design.surfaceLight.opacity(0.4), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 100)
            .offset(x: shimmerOffset)
            .mask(
                RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                    .fill(Color.white)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    shimmerOffset = geo.size.width + 200
                }
            }
        }
    }
}

// MARK: - Empty Feed View

private struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: Design.paddingLG) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Design.textSecondary)
            VStack(spacing: Design.paddingSM) {
                Text("No creations yet")
                    .font(Design.headlineFont)
                    .foregroundStyle(Design.textPrimary)
                Text("Be the first! Head to the Studio\nand create something amazing.")
                    .font(Design.bodyFont)
                    .foregroundStyle(Design.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    FeedView(appState: AppState.preview)
}
