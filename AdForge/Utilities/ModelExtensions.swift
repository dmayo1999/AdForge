// ModelExtensions.swift
// AdForge
//
// Hashable conformances and other conveniences needed by the UI layer.

import Foundation

// MARK: - Sub Hashable (required for NavigationLink(value:))

extension Sub: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Sub, rhs: Sub) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - GenerationType Display

extension GenerationType {
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        }
    }
}
