import SwiftUI

public struct RadarPulseView: View {
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "0D9488").opacity(0.2), lineWidth: 2)
                .frame(width: 180, height: 180)
                .scaleEffect(isPulsing ? 1.4 : 0.8)
                .opacity(isPulsing ? 0 : 0.8)

            Circle()
                .stroke(Color(hex: "0D9488").opacity(0.35), lineWidth: 2)
                .frame(width: 140, height: 140)
                .scaleEffect(isPulsing ? 1.25 : 0.9)
                .opacity(isPulsing ? 0.1 : 0.9)

            Circle()
                .fill(Color(hex: "CCFBF1"))
                .frame(width: 100, height: 100)

            Image(systemName: "paperplane.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "0D9488"))
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
