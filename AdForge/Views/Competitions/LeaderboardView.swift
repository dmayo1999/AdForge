// LeaderboardView.swift
// AdForge

import SwiftUI

struct LeaderboardView: View {
    let entries: [CompetitionEntry]

    private var topThree: [CompetitionEntry] { Array(entries.prefix(3)) }
    private var remaining: [CompetitionEntry] {
        entries.count > 3 ? Array(entries.dropFirst(3)) : []
    }

    var body: some View {
        if entries.isEmpty {
            VStack(spacing: Design.paddingMD) {
                Image(systemName: "trophy")
                    .font(.system(size: 44))
                    .foregroundStyle(Design.textSecondary)
                Text("No entries yet")
                    .font(Design.bodyFont)
                    .foregroundStyle(Design.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: Design.paddingLG) {
                    // Podium for top 3
                    if !topThree.isEmpty {
                        PodiumView(topThree: topThree)
                            .padding(.horizontal, Design.paddingMD)
                    }

                    // Remaining entries
                    if !remaining.isEmpty {
                        VStack(spacing: Design.paddingSM) {
                            Text("Other Entries")
                                .font(Design.captionFont)
                                .foregroundStyle(Design.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Design.paddingMD)

                            ForEach(Array(remaining.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(
                                    entry: entry,
                                    rank: index + 4
                                )
                                .padding(.horizontal, Design.paddingMD)
                            }
                        }
                    }

                    Spacer().frame(height: 120)
                }
                .padding(.top, Design.paddingSM)
            }
        }
    }
}

// MARK: - Podium View

private struct PodiumView: View {
    let topThree: [CompetitionEntry]

    var body: some View {
        VStack(spacing: Design.paddingMD) {
            // Crown / podium display
            HStack(alignment: .bottom, spacing: Design.paddingMD) {
                // 2nd place (left)
                if topThree.count > 1 {
                    PodiumBlock(entry: topThree[1], rank: 2, height: 80)
                }

                // 1st place (center, tallest)
                if !topThree.isEmpty {
                    PodiumBlock(entry: topThree[0], rank: 1, height: 110)
                }

                // 3rd place (right)
                if topThree.count > 2 {
                    PodiumBlock(entry: topThree[2], rank: 3, height: 60)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Design.paddingMD)
        }
        .padding(Design.paddingMD)
        .background(
            LinearGradient(
                colors: [Design.surface, Design.accent.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadiusXL)
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
    }
}

private struct PodiumBlock: View {
    let entry: CompetitionEntry
    let rank: Int
    let height: CGFloat

    private var medalColor: Color {
        switch rank {
        case 1: return Design.credit
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3: return Color(red: 0.72, green: 0.45, blue: 0.20)
        default: return Design.textSecondary
        }
    }

    private var medalIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "number"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Medal icon
            Image(systemName: medalIcon)
                .font(.system(size: rank == 1 ? 22 : 16, weight: .bold))
                .foregroundStyle(medalColor)

            // Thumbnail
            AsyncImage(url: URL(string: entry.mediaURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: rank == 1 ? 72 : 56, height: rank == 1 ? 72 : 56)
                        .clipped()
                default:
                    ZStack {
                        Design.surfaceLight
                        Text(String(entry.userDisplayName.prefix(1)).uppercased())
                            .font(.system(size: rank == 1 ? 22 : 16, weight: .bold, design: .rounded))
                            .foregroundStyle(medalColor)
                    }
                    .frame(width: rank == 1 ? 72 : 56, height: rank == 1 ? 72 : 56)
                }
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(medalColor, lineWidth: rank == 1 ? 3 : 2))
            .shadow(color: medalColor.opacity(0.4), radius: 8, x: 0, y: 4)

            // Name
            Text(entry.userDisplayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Design.textPrimary)
                .lineLimit(1)

            // Vote count
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Design.heart)
                Text("\(entry.voteCount)")
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
            }

            // Podium pillar
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [medalColor.opacity(0.4), medalColor.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(medalColor.opacity(0.4), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: CompetitionEntry
    let rank: Int

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Design.textSecondary)
                .frame(width: 30, alignment: .leading)

            // Thumbnail
            AsyncImage(url: URL(string: entry.mediaURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipped()
                default:
                    Design.surfaceLight
                        .frame(width: 44, height: 44)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusSM))

            // Creator + prompt
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userDisplayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Design.textPrimary)
                Text(entry.prompt)
                    .font(Design.badgeFont)
                    .foregroundStyle(Design.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Vote count
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Design.heart)
                Text("\(entry.voteCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Design.textPrimary)
            }
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

// MARK: - Preview

#Preview {
    ZStack {
        Design.background.ignoresSafeArea()
        LeaderboardView(entries: CompetitionEntry.mocks)
    }
}
