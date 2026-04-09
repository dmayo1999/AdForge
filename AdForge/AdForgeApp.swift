// AdForgeApp.swift
// AdForge

import SwiftUI

@main
struct AdForgeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isAuthenticated {
                    MainTabView(appState: appState)
                } else {
                    AuthView(appState: appState)
                }
            }
            .preferredColorScheme(.dark)
            .environment(appState)
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @Bindable var appState: AppState
    @State private var showDailyCreditsToast = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabContentView(appState: appState)
                .ignoresSafeArea(edges: .bottom)

            // Custom tab bar
            CustomTabBar(selectedTab: $appState.selectedTab)

            // Daily credits toast
            if showDailyCreditsToast {
                DailyCreditsToast()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
            }
        }
        .background(Design.background.ignoresSafeArea())
        .task {
            let collected = await appState.collectDailyCredits()
            if collected {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showDailyCreditsToast = true
                }
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut(duration: 0.3)) {
                    showDailyCreditsToast = false
                }
            }
        }
    }
}

// MARK: - Daily Credits Toast

private struct DailyCreditsToast: View {
    var body: some View {
        HStack(spacing: Design.paddingSM) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Design.credit)
            Text("+500 daily credits")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Design.textPrimary)
        }
        .padding(.horizontal, Design.paddingMD)
        .padding(.vertical, Design.paddingSM)
        .background(
            Capsule()
                .fill(Design.surface)
                .shadow(color: Design.credit.opacity(0.3), radius: 12, x: 0, y: 4)
                .overlay(Capsule().stroke(Design.credit.opacity(0.4), lineWidth: 1))
        )
    }
}

// MARK: - Tab Content Router

private struct TabContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            switch appState.selectedTab {
            case .studio:
                StudioView(appState: appState)
            case .feed:
                FeedView(appState: appState)
            case .competitions:
                CompetitionsView(appState: appState)
            case .profile:
                ProfileView(appState: appState)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.selectedTab)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            // Thin top border
            Rectangle()
                .fill(Design.surfaceLight.opacity(0.6))
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Design.paddingMD)
            .padding(.top, Design.paddingMD)
            .padding(.bottom, 24) // extra for home indicator
            .background(Design.surface)
        }
    }
}

// MARK: - Tab Bar Item

private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Glow effect for active tab
                    if isSelected {
                        Circle()
                            .fill(Design.accent.opacity(0.25))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)
                    }

                    Image(systemName: tab.iconName)
                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? Design.accent : Design.textSecondary)
                        .scaleEffect(isPressed ? 0.88 : 1.0)
                }
                .frame(height: 32)

                // Active indicator dot
                Circle()
                    .fill(isSelected ? Design.accent : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { withAnimation(.easeIn(duration: 0.1)) { isPressed = true } },
            onRelease: { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

// MARK: - Press Events Helper

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
}

private struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

// MARK: - Preview

#Preview {
    MainTabView(appState: AppState.preview)
}
