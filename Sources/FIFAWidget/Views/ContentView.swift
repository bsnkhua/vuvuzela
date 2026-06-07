import SwiftUI

enum WidgetTab: String, CaseIterable {
    case groups = "Groups"
    case matches = "Matches"
    case bracket = "Bracket"
}

struct ContentView: View {
    @State private var activeTab: WidgetTab = .groups
    let store: WorldCupStore

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store, activeTab: $activeTab)
            Divider().background(Theme.cardBorder)

            switch activeTab {
            case .groups:
                GroupsView(store: store)
            case .matches:
                MatchesView(store: store)
            case .bracket:
                BracketView(store: store)
            }
        }
        .background(Theme.background.opacity(
            UserDefaults.standard.object(forKey: WidgetSettings.backgroundOpacityKey) as? Double
                ?? WidgetSettings.defaultOpacity
        ))
        .cornerRadius(10)
    }
}

private struct HeaderView: View {
    let store: WorldCupStore
    @Binding var activeTab: WidgetTab

    var body: some View {
        HStack(spacing: 12) {
            // Logo + title
            HStack(spacing: 6) {
                Text("⚽")
                    .font(.system(size: 14))
                Text("FIFA World Cup 2026")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            // Pill tabs
            HStack(spacing: 2) {
                ForEach(WidgetTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(3)
            .background(Color(white: 1, opacity: 0.06), in: Capsule())

            // Status indicators
            HStack(spacing: 6) {
                if !store.liveMatches.isEmpty {
                    LiveIndicator()
                }
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                } else if let updated = store.lastUpdated {
                    Text(updated, style: .relative)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func tabButton(_ tab: WidgetTab) -> some View {
        let isActive = activeTab == tab
        Button(action: { activeTab = tab }) {
            Text(tab.rawValue)
                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? Theme.tabActive : Theme.tabInactive)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? Color(white: 1, opacity: 0.12) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct LiveIndicator: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Theme.live)
                .frame(width: 6, height: 6)
                .scaleEffect(pulse ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }
            Text("LIVE")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.live)
        }
    }
}
