import AppKit
import SwiftUI

enum WidgetTab: String, CaseIterable {
    case groups = "Groups"
    case matches = "Matches"
    case bracket = "Bracket"
}

public struct ContentView: View {
    @State private var activeTab: WidgetTab = .groups
    let store: WorldCupStore

    public init(store: WorldCupStore) { self.store = store }

    @AppStorage(WidgetSettings.positionLockedKey) private var positionLocked = false
    @AppStorage(WidgetSettings.widgetWidthKey)    private var widgetWidth    = WidgetSettings.defaultWidth
    @AppStorage(WidgetSettings.backgroundOpacityKey) private var backgroundOpacity = WidgetSettings.defaultOpacity
    @State private var dragStartWidth: Double?

    public var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store, activeTab: $activeTab)
            Divider().background(Theme.cardBorder)

            Group {
                switch activeTab {
                case .groups:
                    ScrollView { GroupsView(store: store) }
                case .matches:
                    MatchesView(store: store)
                case .bracket:
                    BracketView(store: store)
                }
            }
            .frame(height: 562)
        }
        .background(Theme.background.opacity(WidgetSettings.clampOpacity(backgroundOpacity)))
        .cornerRadius(10)
        .overlay(alignment: .trailing) {
            resizeHandle
        }
    }

    // Invisible 10-pt strip on the right edge — drag to resize, disabled when locked
    private var resizeHandle: some View {
        Color.clear
            .frame(width: 10)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { inside in
                guard !positionLocked else { return }
                if inside { NSCursor.resizeLeftRight.push() }
                else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        guard !positionLocked else { return }
                        let start = dragStartWidth ?? widgetWidth
                        dragStartWidth = start
                        widgetWidth = WidgetSettings.clampWidth(start + value.translation.width)
                    }
                    .onEnded { _ in dragStartWidth = nil }
            )
    }
}

private struct HeaderView: View {
    let store: WorldCupStore
    @Binding var activeTab: WidgetTab
    @AppStorage(WidgetSettings.positionLockedKey) private var positionLocked = false

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

            // Status indicators + lock
            HStack(spacing: 6) {
                if !store.liveMatches.isEmpty {
                    LiveIndicator()
                }
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                } else if let updated = store.lastUpdated, !store.liveMatches.isEmpty {
                    Text(updated, style: .relative)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textDim)
                        .frame(width: 36, alignment: .trailing)
                }
                lockButton
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

    private var lockButton: some View {
        Button {
            positionLocked.toggle()
        } label: {
            Image(systemName: positionLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(positionLocked ? Theme.warning : Theme.textDim)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(positionLocked
            ? "Position locked — click to unlock"
            : "Click to lock the widget position")
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
