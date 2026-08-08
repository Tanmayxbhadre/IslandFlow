import SwiftUI

public struct ExpandedIslandView: View {
    @ObservedObject var appState: AppState
    
    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "circle.hexagonpath.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("IslandFlow")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("System HUD")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.cyan)
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Native macOS Floating HUD")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    
                    Text("Click to collapse island")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: IslandState.expanded.size.width, height: IslandState.expanded.size.height)
    }
}
