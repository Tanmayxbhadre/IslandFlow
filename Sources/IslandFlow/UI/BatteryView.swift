import SwiftUI

public struct BatteryView: View {
    let state: BatteryState
    
    private var iconName: String {
        if state.isCritical || state.isLow {
            return "exclamationmark.triangle.fill"
        } else if state.isCharging {
            return "bolt.fill"
        } else if state.percentage >= 95 {
            return "battery.100"
        } else if state.percentage >= 65 {
            return "battery.75"
        } else if state.percentage >= 35 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
    
    private var iconColor: Color {
        if state.isCritical {
            return .red
        } else if state.isLow {
            return .yellow
        } else if state.isCharging {
            return .green
        } else {
            return .white
        }
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 1) {
                if state.isCritical {
                    Text("Critical Battery · \(state.percentage)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                } else if state.isLow {
                    Text("Low Battery · \(state.percentage)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                } else if state.isCharging {
                    Text("Charging · \(state.percentage)%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                } else if state.isFull {
                    Text("Battery Full · 100%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("Battery · \(state.percentage)%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
    }
}
