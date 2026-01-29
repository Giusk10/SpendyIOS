import SwiftUI

enum TabBarItem: String, CaseIterable {
    case home
    case upload
    case analytics

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .upload: return "plus.circle.fill"
        case .analytics: return "chart.pie.fill"
        }
    }
    
    var iconNameOutline: String {
        switch self {
        case .home: return "house"
        case .upload: return "plus.circle"
        case .analytics: return "chart.pie"
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
