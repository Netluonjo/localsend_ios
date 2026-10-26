import SwiftUI
import QuickLook

public struct HistoryView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var previewURL: URL?

    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.transferHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "64748B").opacity(0.5))

                        Text("Chưa có lịch sử truyền nhận nào")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "64748B"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.transferHistory) { item in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(item.isIncoming ? Color(hex: "CCFBF1") : Color(hex: "E0F2FE"))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: item.isIncoming ? "arrow.down.left" : "arrow.up.right")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(item.isIncoming ? Color(hex: "0D9488") : Color(hex: "0284C7"))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "0F172A"))
                                        .lineLimit(1)

                                    Text("\(item.senderOrReceiver) • \(item.formattedSize) • \(item.formattedTime)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "64748B"))
                                }

                                Spacer()

                                if let url = item.fileURL {
                                    Button(action: {
                                        previewURL = url
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(Color(hex: "0D9488"))
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.white)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Lịch sử truyền nhận")
            .background(Color(hex: "F8FAFC"))
            .sheet(item: $previewURL) { url in
                ActivityView(activityItems: [url])
            }
        }
    }
}

// Helper wrapper for UIActivityViewController in SwiftUI
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
