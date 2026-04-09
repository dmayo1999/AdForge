// Extensions.swift
// AdForge
//
// Reusable Swift / SwiftUI extensions used across the codebase.

import SwiftUI
import UIKit
import Foundation

// MARK: - Color + Hex

extension Color {
    /// Creates a Color from a hex string such as "#7C3AED" or "7C3AED".
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let length = cleaned.count
        if length == 6 {
            let r = Double((rgb >> 16) & 0xFF) / 255.0
            let g = Double((rgb >>  8) & 0xFF) / 255.0
            let b = Double( rgb        & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else if length == 8 {
            let r = Double((rgb >> 24) & 0xFF) / 255.0
            let g = Double((rgb >> 16) & 0xFF) / 255.0
            let b = Double((rgb >>  8) & 0xFF) / 255.0
            let a = Double( rgb        & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        } else {
            // Fallback to clear
            self.init(red: 0, green: 0, blue: 0)
        }
    }
}

// MARK: - Date Formatting

extension Date {
    /// Returns a human-friendly relative string: "just now", "2m ago", "3h ago", "4d ago", "Mar 5".
    var relativeString: String {
        let seconds = Int(Date().timeIntervalSince(self))
        switch seconds {
        case ..<60:
            return "just now"
        case 60..<3600:
            let m = seconds / 60
            return "\(m)m ago"
        case 3600..<86400:
            let h = seconds / 3600
            return "\(h)h ago"
        case 86400..<604800:
            let d = seconds / 86400
            return "\(d)d ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }
    }

    /// e.g. "Mar 5, 2025"
    var mediumString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// e.g. "9:41 AM"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date was yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

extension TimeInterval {
    /// Formats a TimeInterval as a countdown string, e.g. "23h 47m" or "45m 12s".
    var countdownString: String {
        let totalSeconds = Int(self)
        if totalSeconds >= 3600 {
            let h = totalSeconds / 3600
            let m = (totalSeconds % 3600) / 60
            return "\(h)h \(m)m"
        } else if totalSeconds >= 60 {
            let m = totalSeconds / 60
            let s = totalSeconds % 60
            return "\(m)m \(s)s"
        } else {
            return "\(totalSeconds)s"
        }
    }
}

// MARK: - Number Formatting

extension Int {
    /// Returns a compact string: 999 → "999", 1234 → "1.2k", 1_200_000 → "1.2M".
    var compactString: String {
        switch self {
        case ..<1000:
            return "\(self)"
        case 1000..<1_000_000:
            let k = Double(self) / 1_000.0
            return k.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(k))k"
                : String(format: "%.1fk", k)
        default:
            let m = Double(self) / 1_000_000.0
            return m.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(m))M"
                : String(format: "%.1fM", m)
        }
    }
}

extension Double {
    /// Returns a compact string with the same logic as Int.compactString.
    var compactString: String { Int(self).compactString }
}

// MARK: - View Extensions

extension View {

    // MARK: Conditional Modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: AdForge Card Style
    func adForgeCard(padding: CGFloat = Design.paddingMD) -> some View {
        self
            .padding(padding)
            .background(Design.surface)
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
    }

    // MARK: AdForge Surface Style (elevated)
    func adForgeSurface(padding: CGFloat = Design.paddingMD) -> some View {
        self
            .padding(padding)
            .background(Design.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadiusSM))
    }

    // MARK: Gradient Button Background
    func accentGradientBackground(cornerRadius: CGFloat = Design.cornerRadius) -> some View {
        self.background(
            LinearGradient(
                colors: [Design.accent, Design.accentLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        )
    }

    // MARK: Hide Keyboard
    func hideKeyboard() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    // MARK: Loading Overlay
    func loadingOverlay(_ isLoading: Bool, message: String = "Loading…") -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    VStack(spacing: Design.paddingMD) {
                        ProgressView()
                            .tint(Design.accentLight)
                            .scaleEffect(1.4)
                        Text(message)
                            .font(Design.captionFont)
                            .foregroundStyle(Design.textSecondary)
                    }
                    .padding(Design.paddingLG)
                    .background(Design.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius))
                }
            }
        }
    }

    // MARK: Error Banner
    func errorBanner(_ message: Binding<String?>) -> some View {
        self.overlay(alignment: .top) {
            if let msg = message.wrappedValue {
                Text(msg)
                    .font(Design.captionFont)
                    .foregroundStyle(.white)
                    .padding(Design.paddingMD)
                    .frame(maxWidth: .infinity)
                    .background(Design.error)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { message.wrappedValue = nil }
                    .task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        message.wrappedValue = nil
                    }
            }
        }
        .animation(.spring(duration: 0.3), value: message.wrappedValue)
    }
}

// MARK: - Image Extensions

extension UIImage {
    /// Resizes the image to the target size while maintaining aspect ratio.
    func resized(to targetSize: CGSize) -> UIImage {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Returns the first N characters, padded with "…" if truncated.
    func truncated(to length: Int) -> String {
        guard count > length else { return self }
        return String(prefix(length)) + "…"
    }

    /// Returns true if this string is not empty after trimming whitespace.
    var isNotEmpty: Bool { !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
