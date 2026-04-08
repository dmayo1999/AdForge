// ShareSheet.swift
// AdForge

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Convenience initializer with image + text

extension ShareSheet {
    /// Share a remote URL (image or video) alongside a text message.
    init(mediaURLString: String, caption: String, generationId: String) {
        let deepLink = "adforge://generation/\(generationId)"
        let shareText = "\(caption)\n\nMade with AdForge 🎨 \(deepLink)"
        self.items = [shareText, mediaURLString]
    }
}

// MARK: - Preview

#Preview {
    ShareSheet(
        items: [
            "Check out what I made with AdForge! adforge://generation/preview-123",
            "https://example.com/image.jpg"
        ]
    )
}
