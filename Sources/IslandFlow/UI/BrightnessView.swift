import SwiftUI

public struct BrightnessView: View {
    let state: BrightnessState
    
    private var iconName: String {
        if state.level > 66 {
            return "sun.max.fill"
        } else if state.level > 33 {
            return "sun.max"
        } else {
            return "sun.min.fill"
        }
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
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
        .padding(.horizontal, 14)
        .frame(height: 42)
    }
}
