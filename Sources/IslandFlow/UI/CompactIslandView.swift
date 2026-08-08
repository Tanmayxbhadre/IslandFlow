import SwiftUI

public struct CompactIslandView: View {
    @ObservedObject var appState: AppState
    
    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isHovered ? Color.cyan : Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: appState.isHovered ? .cyan.opacity(0.8) : .white.opacity(0.4), radius: 4)
            
            Text("IslandFlow")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: IslandState.compact.size.height)
    }
}
