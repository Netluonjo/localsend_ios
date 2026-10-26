import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            ReceiveView(viewModel: viewModel)
                .tabItem {
                    Label("Nhận", systemImage: "tray.and.arrow.down.fill")
                }
                .tag(0)

            SendView(viewModel: viewModel)
                .tabItem {
                    Label("Gửi", systemImage: "paperplane.fill")
                }
                .tag(1)

            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("Lịch sử", systemImage: "clock.fill")
                }
                .tag(2)
        }
        .tint(Color(hex: "0D9488"))
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Thông báo"),
                message: Text(viewModel.alertMessage ?? ""),
                dismissButton: .default(Text("Đóng"))
            )
        }
    }
}
