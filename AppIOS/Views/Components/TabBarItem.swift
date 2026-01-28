import SwiftUI

enum TabBarItem: String, CaseIterable {
    case home
    case upload
    case analytics

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .upload: return "arrow.up.doc.fill"
        case .analytics: return "chart.pie.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .upload: return "Carica"
        case .analytics: return "Analytics"
        }
    }
}
