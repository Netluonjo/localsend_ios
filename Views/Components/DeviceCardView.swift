import SwiftUI

public struct DeviceCardView: View {
    public let device: Device
    public let onSend: () -> Void

    public init(device: Device, onSend: @escaping () -> Void) {
        self.device = device
        self.onSend = onSend
    }

    private var deviceIcon: String {
        switch device.deviceType.lowercased() {
        case "desktop": return "desktopcomputer"
        case "mobile": return "iphone"
        case "tablet": return "ipad"
        default: return "laptopcomputer"
        }
    }

    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "CCFBF1"))
                    .frame(width: 48, height: 48)

                Image(systemName: deviceIcon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "0D9488"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(device.alias)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "0F172A"))

                Text("\(device.ip) : \(device.port) • \(device.deviceModel)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "64748B"))
            }

            Spacer()

            Button(action: onSend) {
                Text("Gửi")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "0D9488"))
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
}
