import SwiftUI

public struct ReceiveView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isCopied = false

    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }

    private var webShareURL: String {
        "http://\(viewModel.myIP):\(LocalSendProtocol.port)"
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Device Info
                HStack(spacing: 12) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "0D9488"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.myAlias)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "0F172A"))

                        Text("IP: \(viewModel.myIP) : \(LocalSendProtocol.port)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "64748B"))
                    }

                    Spacer()

                    Text("Sẵn sàng")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "115E59"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "CCFBF1"))
                        .cornerRadius(12)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
                )

                // Radar animation
                VStack(spacing: 16) {
                    RadarPulseView()
                        .padding(.top, 20)

                    Text("Sẵn sàng nhận dữ liệu")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "0F172A"))

                    Text("Mọi thiết bị cùng mạng Wi-Fi (Android, PC, Mac) có thể tìm thấy và gửi tệp cho bạn.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "64748B"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Web Share Card for Safari / Browser
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🌐 Dùng trên Trình duyệt / Safari")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "115E59"))

                        Spacer()

                        Button(action: {
                            UIPasteboard.general.string = webShareURL
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        }) {
                            Text(isCopied ? "Đã sao chép!" : "Sao chép")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "0D9488"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                    }

                    Text(webShareURL)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "0F172A"))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(10)

                    Text("Mở liên kết trên từ máy tính hoặc điện thoại khác cùng mạng Wi-Fi để gửi & nhận file mà không cần cài app!")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "115E59"))
                }
                .padding(16)
                .background(Color(hex: "CCFBF1"))
                .cornerRadius(16)
            }
            .padding(20)
        }
        .background(Color(hex: "F8FAFC").ignoresSafeArea())
        .refreshable {
            viewModel.refreshNetwork()
        }
    }
}
