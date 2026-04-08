// WatermarkRenderer.swift
// AdForge
//
// Applies a "made with AdForge" watermark to UIImages using Core Graphics.
// Used before sharing or exporting generated content.

import UIKit
import CoreGraphics

// MARK: - WatermarkRenderer

enum WatermarkRenderer {

    // MARK: - Configuration

    private static let watermarkText = "made with AdForge"
    private static let margin: CGFloat = 16
    private static let cornerRadius: CGFloat = 10

    // MARK: - Public API

    /// Returns a new UIImage with the AdForge watermark composited in the bottom-right corner.
    /// If rendering fails, returns the original image unmodified.
    static func applyWatermark(to image: UIImage) -> UIImage {
        let imageSize = image.size
        let scale = image.scale

        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return image }

        // Draw the original image
        image.draw(in: CGRect(origin: .zero, size: imageSize))

        // Build watermark attributes
        let font = UIFont.systemFont(ofSize: max(12, imageSize.width * 0.028), weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.92)
        ]

        let text = NSString(string: watermarkText)
        let textSize = text.size(withAttributes: attributes)

        let pillWidth  = textSize.width  + margin * 2
        let pillHeight = textSize.height + margin * 0.8

        // Position: bottom-right corner
        let pillX = imageSize.width  - pillWidth  - margin
        let pillY = imageSize.height - pillHeight - margin
        let pillRect = CGRect(x: pillX, y: pillY, width: pillWidth, height: pillHeight)

        // Draw pill background
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: cornerRadius)
        UIColor.black.withAlphaComponent(0.45).setFill()
        context.saveGState()
        pillPath.fill()
        context.restoreGState()

        // Draw text centered in pill
        let textX = pillX + (pillWidth  - textSize.width)  / 2
        let textY = pillY + (pillHeight - textSize.height) / 2
        let textRect = CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height)
        text.draw(in: textRect, withAttributes: attributes)

        // Draw AdForge icon (⬡ approximation using a colored dot)
        let iconSize: CGFloat = font.pointSize * 1.1
        let iconX = pillX + margin * 0.5 - iconSize * 0.5 - 2
        let iconY = pillY + (pillHeight - iconSize) / 2
        let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
        UIColor(red: 0.655, green: 0.545, blue: 0.980, alpha: 0.95).setFill()
        UIBezierPath(ovalIn: iconRect).fill()

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - Async Variant

    /// Async wrapper so watermark rendering can be called from async contexts without blocking MainActor.
    static func applyWatermark(to image: UIImage) async -> UIImage {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let watermarked = applyWatermark(to: image)
                continuation.resume(returning: watermarked)
            }
        }
    }

    // MARK: - Batch

    /// Applies the watermark to multiple images concurrently.
    static func applyWatermarks(to images: [UIImage]) async -> [UIImage] {
        await withTaskGroup(of: (Int, UIImage).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let watermarked: UIImage = await applyWatermark(to: image)
                    return (index, watermarked)
                }
            }

            var results = [(Int, UIImage)]()
            for await result in group {
                results.append(result)
            }
            // Reassemble in original order
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}
