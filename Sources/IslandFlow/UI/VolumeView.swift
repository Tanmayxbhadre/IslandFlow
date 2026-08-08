import SwiftUI

public struct VolumeView: View {
    let state: VolumeState
    
    private var iconName: String {
        if state.isMuted || state.level == 0 {
            return "speaker.slash.fill"
        } else if state.level > 66 {
            return "speaker.wave.3.fill"
        } else if state.level > 33 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.1.fill"
        }
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(state.isMuted ? .secondary : .white)
                .frame(width: 20)
            
            if state.isMuted {
                Text("Muted")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(state.level) / 100.0, height: 6)
                    }
                    .frame(height: geometry.size.height)
                }
                .frame(height: 6)
                
                Text("\(state.level)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
    }
}
