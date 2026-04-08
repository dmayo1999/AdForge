// AuthView.swift
// AdForge

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Bindable var appState: AppState

    @State private var orbScale: CGFloat = 1.0
    @State private var orbOpacity: Double = 0.7
    @State private var logoOffset: CGFloat = 20
    @State private var logoOpacity: Double = 0
    @State private var isSigningIn: Bool = false

    var body: some View {
        ZStack {
            // Background
            Design.background.ignoresSafeArea()

            // Animated gradient orb
            AnimatedOrb()

            VStack(spacing: 0) {
                Spacer()

                // Logo + headline
                VStack(spacing: Design.paddingMD) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Design.accent, Design.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Design.accent.opacity(0.5), radius: 20, x: 0, y: 8)

                    Text("AdForge")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(Design.textPrimary)

                    Text("Create. Compete. Win.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Design.textSecondary)
                        .tracking(1.5)
                }
                .offset(y: logoOffset)
                .opacity(logoOpacity)

                Spacer()

                // Feature bullets
                VStack(spacing: Design.paddingMD) {
                    FeatureBullet(
                        icon: "paintbrush.pointed.fill",
                        color: Color(red: 0.6, green: 0.3, blue: 1.0),
                        title: "AI Images",
                        subtitle: "Flux Pro & Dev models"
                    )
                    FeatureBullet(
                        icon: "film.fill",
                        color: Color(red: 0.3, green: 0.7, blue: 1.0),
                        title: "AI Videos",
                        subtitle: "Wan 2.5 cinematic clips"
                    )
                    FeatureBullet(
                        icon: "trophy.fill",
                        color: Design.credit,
                        title: "Competitions",
                        subtitle: "Daily challenges & leaderboards"
                    )
                }
                .padding(.horizontal, Design.paddingXL)
                .offset(y: logoOffset)
                .opacity(logoOpacity)

                Spacer()

                // Sign-in section
                VStack(spacing: Design.paddingMD) {
                    SignInWithAppleButtonView(isSigningIn: $isSigningIn) {
                        Task { await signIn() }
                    }
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.cornerRadius)
                            .stroke(Design.surfaceLight, lineWidth: 1)
                    )

                    Text("We only use your Apple ID to create your account.\nWe never share your data.")
                        .font(Design.captionFont)
                        .foregroundStyle(Design.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, Design.paddingXL)
                .padding(.bottom, 48)
                .offset(y: logoOffset)
                .opacity(logoOpacity)
            }

            // Error overlay
            if let errorMessage = appState.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(Design.captionFont)
                        .foregroundStyle(Design.textPrimary)
                        .padding(Design.paddingMD)
                        .background(Design.error.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusSM))
                        .padding(.horizontal, Design.paddingMD)
                        .padding(.bottom, 120)
                        .onTapGesture { appState.errorMessage = nil }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoOffset = 0
                logoOpacity = 1
            }
        }
    }

    private func signIn() async {
        isSigningIn = true
        do {
            _ = try await appState.authService.signInWithApple()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
        isSigningIn = false
    }
}

// MARK: - Animated Orb

private struct AnimatedOrb: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 240
                    )
                )
                .frame(width: 480, height: 480)
                .scaleEffect(scale)
                .opacity(opacity)
                .blur(radius: 20)

            // Core orb
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.49, green: 0.23, blue: 0.93),
                            Color(red: 0.86, green: 0.27, blue: 0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 180)
                .blur(radius: 50)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale * 0.9)
                .opacity(opacity)
        }
        .offset(y: -200)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.2
                opacity = 0.9
            }
            withAnimation(
                .linear(duration: 8.0)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Feature Bullet

private struct FeatureBullet: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Design.paddingMD) {
            ZStack {
                RoundedRectangle(cornerRadius: Design.cornerRadiusSM)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.bodyFont.weight(.semibold))
                    .foregroundStyle(Design.textPrimary)
                Text(subtitle)
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
                .stroke(Design.surfaceLight, lineWidth: 1)
        )
    }
}

// MARK: - Sign In With Apple UIViewRepresentable

struct SignInWithAppleButtonView: UIViewRepresentable {
    @Binding var isSigningIn: Bool
    let onTap: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType: .signIn,
            authorizationButtonStyle: .white
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleTap),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        uiView.alpha = isSigningIn ? 0.6 : 1.0
        uiView.isEnabled = !isSigningIn
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    class Coordinator {
        let onTap: () -> Void
        init(onTap: @escaping () -> Void) { self.onTap = onTap }
        @objc func handleTap() { onTap() }
    }
}

// MARK: - Preview

#Preview {
    AuthView(appState: AppState.preview)
}
