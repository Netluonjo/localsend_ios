import Foundation
import SwiftUI
import Combine

@MainActor
public final class MainViewModel: ObservableObject {
    @Published public var myAlias: String = "LocalSend (iPhone)"
    @Published public var myIP: String = "127.0.0.1"
    @Published public var discoveredDevices: [Device] = []
    @Published public var transferHistory: [TransferItem] = []
    @Published public var selectedFileURL: URL?
    @Published public var selectedText: String?
    @Published public var isScanning: Bool = false
    @Published public var alertMessage: String?
    @Published public var showAlert: Bool = false

    private let fingerprint = LocalSendProtocol.certificateFingerprint
    private var udpService: UdpDiscoveryService?
    private var httpServer: LocalHttpServer?
    private var clientSender: ClientSender?
    private var deviceScanner: DeviceScanner?

    public init() {
        self.myIP = LocalSendProtocol.getLocalIPAddress()
        self.clientSender = ClientSender(senderAlias: myAlias, senderFingerprint: fingerprint)

        setupHttpServer()
        setupUdpDiscovery()
    }

    public func refreshNetwork() {
        self.myIP = LocalSendProtocol.getLocalIPAddress()
        udpService?.sendAnnouncement(announce: true)
        startScan()
    }

    private func setupHttpServer() {
        httpServer = LocalHttpServer(
            deviceAlias: myAlias,
            fingerprint: fingerprint,
            port: LocalSendProtocol.port,
            getSharedFile: { [weak self] in
                guard let self = self, let url = self.selectedFileURL else { return nil }
                let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                return SharedFileMetadata(url: url, fileName: url.lastPathComponent, fileSize: size)
            },
            onDeviceRegistered: { [weak self] device in
                self?.addOrUpdateDevice(device)
            },
            onFileReceived: { [weak self] item, url in
                self?.transferHistory.insert(item, at: 0)
                self?.showAlert(message: "Đã nhận tệp: \(item.name)")
            },
            onTextReceived: { [weak self] sender, text in
                let item = TransferItem(
                    name: "Tin nhắn: \(text)",
                    size: Int64(text.utf8.count),
                    senderOrReceiver: sender,
                    isIncoming: true
                )
                self?.transferHistory.insert(item, at: 0)
                self?.showAlert(message: "Nhận tin nhắn từ \(sender):\n\(text)")
            }
        )
        httpServer?.start()
    }

    private func setupUdpDiscovery() {
        udpService = UdpDiscoveryService(
            deviceAlias: myAlias,
            fingerprint: fingerprint,
            onDeviceFound: { [weak self] device in
                self?.addOrUpdateDevice(device)
            }
        )
        udpService?.start()
    }

    public func startScan() {
        isScanning = true
        discoveredDevices.removeAll()

        udpService?.sendAnnouncement(announce: true)

        deviceScanner = DeviceScanner(myIP: myIP, myFingerprint: fingerprint) { [weak self] device in
            self?.addOrUpdateDevice(device)
        }

        Task {
            await deviceScanner?.scan()
            self.isScanning = false
        }
    }

    private func addOrUpdateDevice(_ device: Device) {
        if let index = discoveredDevices.firstIndex(where: { $0.ip == device.ip }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
    }

    public func selectFile(_ url: URL) {
        self.selectedFileURL = url
        self.selectedText = nil
    }

    public func selectText(_ text: String) {
        self.selectedText = text
        self.selectedFileURL = nil
    }

    public func clearSelection() {
        self.selectedFileURL = nil
        self.selectedText = nil
    }

    public func sendToDevice(_ device: Device) {
        guard selectedFileURL != nil || selectedText != nil else {
            showAlert(message: "Vui lòng chọn tệp hoặc nhập văn bản trước khi gửi!")
            return
        }

        Task {
            let result: SendResult
            let itemName: String
            let itemSize: Int64

            if let text = selectedText {
                itemName = "Tin nhắn: \(text)"
                itemSize = Int64(text.utf8.count)
                result = await clientSender?.sendText(device: device, text: text) ?? .error("Lỗi gửi")
            } else if let fileURL = selectedFileURL {
                itemName = fileURL.lastPathComponent
                itemSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
                result = await clientSender?.sendFile(device: device, fileURL: fileURL) ?? .error("Lỗi gửi")
            } else {
                return
            }

            switch result {
            case .success:
                let historyItem = TransferItem(
                    name: itemName,
                    size: itemSize,
                    senderOrReceiver: device.alias,
                    isIncoming: false,
                    status: "Hoàn tất"
                )
                self.transferHistory.insert(historyItem, at: 0)
                self.clearSelection()
                self.showAlert(message: "Gửi thành công tới \(device.alias)!")

            case .declined:
                self.showAlert(message: "\(device.alias) đã từ chối yêu cầu nhận file!")

            case .error(let msg):
                self.showAlert(message: "Gửi thất bại: \(msg)")
            }
        }
    }

    private func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
}
