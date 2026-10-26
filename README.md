# LocalSend iOS (Native Swift & SwiftUI)

Phiên bản Native iOS dành riêng cho iPhone & iPad, được viết bằng **Swift & SwiftUI** hiện đại, tuân thủ đúng chuẩn **Giao thức LocalSend v2**.

---

## 🚀 Các Tính Năng Chính (Giống App Store)

1. **Chuẩn Giao Thức LocalSend v2**:
   - Sử dụng cổng mạng `53317` và địa chỉ Multicast UDP `224.0.0.167`.
   - Kết nối hai chiều với bản **Android Native**, bản **Windows PC**, **Mac** và bản chính thức trên **App Store**.
2. **Khám Phá Thiết Bị (Device Discovery)**:
   - Tự động phát hiện thiết bị qua Multicast UDP (`Network.framework`).
   - Tích hợp tính năng quét dải IP Subnet tự động (`DeviceScanner`) khi mạng Wi-Fi chặn gói tin Multicast.
3. **Truyền & Nhận Dữ Liệu Tốc Độ Cao**:
   - Chọn tệp tin từ ứng dụng Tệp (Files) qua `fileImporter`.
   - Chọn Ảnh / Video độ phân giải gốc qua `PhotosPicker`.
   - Gửi tin nhắn văn bản tức thì.
4. **Tích Hợp Web Share (Trình duyệt Safari)**:
   - Tích hợp sẵn máy chủ HTTP mini nội bộ (`LocalHttpServer`).
   - Cho phép các máy tính/điện thoại khác trong mạng Wi-Fi truy cập qua Safari/Chrome (`http://[IP_iPhone]:53317`) để tải lên hoặc tải về file trực tiếp.
5. **Giao Diện Chuẩn Apple (SwiftUI)**:
   - Hiệu ứng sóng Radar quét thiết bị xung quanh.
   - 3 Tab điều hướng chính: **Nhận**, **Gửi**, **Lịch sử**.
   - Hỗ trợ xem nhanh và chia sẻ file qua **iOS Share Sheet**.

---

## 📁 Cấu Trúc Dự Án

```
ios/LocalSendIOS/
├── LocalSendIOSApp.swift          # Entry point của ứng dụng iOS
├── Info.plist                     # Quyền truy cập Local Network & Thư viện ảnh
├── Package.swift                  # Swift Package Manager manifest
├── Models/
│   ├── Device.swift               # Model thiết bị nhận/gửi
│   ├── TransferItem.swift         # Model lưu lịch sử truyền file
│   └── LocalSendProtocol.swift    # Hằng số giao thức & IP Resolver (getifaddrs)
├── Network/
│   ├── UdpDiscoveryService.swift  # Phát hiện thiết bị bằng UDP Multicast
│   ├── LocalHttpServer.swift      # Server HTTP nhận file & phục vụ Safari Web Share
│   ├── ClientSender.swift         # Gửi file/text qua REST API (URLSession)
│   └── DeviceScanner.swift        # Quét dải IP mạng nội bộ Subnet
├── ViewModels/
│   └── MainViewModel.swift        # Quản lý trạng thái và luồng dữ liệu
└── Views/
    ├── ContentView.swift          # TabView chính
    ├── ReceiveView.swift          # Màn hình Nhận (Radar + Web Share)
    ├── SendView.swift             # Màn hình Gửi (Bộ chọn file/ảnh + Radar)
    ├── HistoryView.swift          # Màn hình Lịch sử truyền nhận
    └── Components/
        ├── RadarPulseView.swift   # Hiệu ứng vòng tròn Radar
        └── DeviceCardView.swift   # Thẻ thiết bị tìm thấy
```

---

## 🛠 Hướng Dẫn Mở & Chạy Dự Án

### Cách 1: Mở trực tiếp trên Mac bằng Xcode
1. Mở Xcode trên macOS.
2. Chọn **File -> Open...** và trỏ tới thư mục `ios/LocalSendIOS` (hoặc mở tệp `Package.swift`).
3. Chọn thiết bị đích (iPhone hoặc Simulator) và bấm **Run (Cmd + R)**.

### Cách 2: Tạo Xcode Project mới (App iOS)
1. Trong Xcode, tạo dự án mới: **iOS -> App**, đặt tên `LocalSendIOS`, chọn Interface là **SwiftUI**.
2. Kéo toàn bộ các thư mục `Models/`, `Network/`, `ViewModels/`, `Views/` và `Info.plist` vào dự án.
3. Ký Certificate (Apple ID miễn phí) và cắm cáp iPhone để cài đặt.

### Cách 3: Build tự động qua GitHub Actions (Không cần Mac)
Nếu bạn đang dùng máy tính Windows, có thể đẩy mã nguồn này lên GitHub và sử dụng GitHub Actions với môi trường `macos-latest` để tự động biên dịch thành file `.ipa` rồi cài lên iPhone qua **AltStore** hoặc **Sideloadly**.
