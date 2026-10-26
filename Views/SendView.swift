import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public struct SendView: View {
    @ObservedObject var viewModel: MainViewModel

    @State private var isShowingFilePicker = false
    @State private var isShowingTextSheet = false
    @State private var inputText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?

    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Chọn dữ liệu muốn gửi")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "0F172A"))

                    // Action buttons grid
                    HStack(spacing: 12) {
                        Button(action: { isShowingFilePicker = true }) {
                            HStack {
                                Image(systemName: "doc.fill")
                                Text("Tệp tin")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "0D9488"))
                            .cornerRadius(12)
                        }

                        PhotosPicker(selection: $selectedPhotoItem, matching: .any(of: [.images, .videos])) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Ảnh / Video")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "0D9488"))
                            .cornerRadius(12)
                        }
                    }

                    Button(action: { isShowingTextSheet = true }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Gửi Văn Bản / Tin Nhắn")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "0D9488"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "0D9488"), lineWidth: 1.5)
                        )
                    }

                    // Selected Item Card
                    if viewModel.selectedFileURL != nil || viewModel.selectedText != nil {
                        HStack {
                            Image(systemName: viewModel.selectedText != nil ? "text.bubble.fill" : "doc.badge.arrow.up.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "115E59"))

                            Text(selectedItemTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "115E59"))
                                .lineLimit(1)

                            Spacer()

                            Button(action: { viewModel.clearSelection() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "115E59").opacity(0.7))
                            }
                        }
                        .padding(14)
                        .background(Color(hex: "CCFBF1"))
                        .cornerRadius(14)
                    }

                    // Devices section header
                    HStack {
                        Text("Thiết bị xung quanh")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "0F172A"))

                        Spacer()

                        Button(action: { viewModel.startScan() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "0D9488"))
                                .rotationEffect(Angle(degrees: viewModel.isScanning ? 360 : 0))
                                .animation(viewModel.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isScanning)
                        }
                    }
                    .padding(.top, 10)

                    // Discovered devices list
                    if viewModel.discoveredDevices.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .padding(.top, 20)

                            Text(viewModel.isScanning ? "Đang quét mạng Wi-Fi tìm thiết bị..." : "Chưa tìm thấy thiết bị nào trong mạng Wi-Fi.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "64748B"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.discoveredDevices) { device in
                                DeviceCardView(device: device) {
                                    viewModel.sendToDevice(device)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(hex: "F8FAFC").ignoresSafeArea())
        .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                viewModel.selectFile(url)
            case .failure(let error):
                print("Lỗi chọn tệp: \(error)")
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("photo_\(Int(Date().timeIntervalSince1970)).jpg")
                    try? data.write(to: tempURL)
                    viewModel.selectFile(tempURL)
                }
            }
        }
        .sheet(isPresented: $isShowingTextSheet) {
            VStack(spacing: 16) {
                Text("Nhập Văn Bản Cần Chia Sẻ")
                    .font(.headline)
                    .padding(.top)

                TextEditor(text: $inputText)
                    .padding(8)
                    .background(Color(hex: "F8FAFC"))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "E2E8F0"), lineWidth: 1))
                    .frame(height: 120)

                HStack {
                    Button("Hủy") {
                        isShowingTextSheet = false
                    }
                    .foregroundColor(.gray)

                    Spacer()

                    Button("Xong") {
                        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.selectText(inputText)
                            inputText = ""
                            isShowingTextSheet = false
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color(hex: "0D9488"))
                }
                .padding(.top, 8)
            }
            .padding()
            .presentationDetents([.height(250)])
        }
    }

    private var selectedItemTitle: String {
        if let text = viewModel.selectedText {
            return "Đã chọn tin nhắn: \"\(text)\""
        } else if let url = viewModel.selectedFileURL {
            return "Đã chọn: \(url.lastPathComponent)"
        }
        return ""
    }
}
