import Foundation
import Network

public final class UdpDiscoveryService {
    private var listener: NWListener?
    private var isRunning = false
    private let deviceAlias: String
    private let fingerprint: String
    private let onDeviceFound: (Device) -> Void

    public init(
        deviceAlias: String,
        fingerprint: String,
        onDeviceFound: @escaping (Device) -> Void
    ) {
        self.deviceAlias = deviceAlias
        self.fingerprint = fingerprint
        self.onDeviceFound = onDeviceFound
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true

            // Lắng nghe trên cổng multicast 53317
            let endpoint = NWEndpoint.Port(rawValue: LocalSendProtocol.port)!
            listener = try NWListener(using: params, on: endpoint)

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }

            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("[UdpDiscovery] Listener sẵn sàng trên cổng \(LocalSendProtocol.port)")
                    self?.sendAnnouncement(announce: true)
                case .failed(let error):
                    print("[UdpDiscovery] Listener lỗi: \(error)")
                default:
                    break
                }
            }

            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("[UdpDiscovery] Không thể khởi động listener: \(error)")
        }
    }

    public func stop() {
        isRunning = false
        listener?.cancel()
        listener = nil
    }

    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            guard let self = self, let data = data, !data.isEmpty else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let remoteIP = (connection.endpoint as? NWEndpoint)?.debugDescription {
                self.processPacket(json: json, remoteEndpoint: connection.endpoint)
            }
            connection.cancel()
        }
    }

    private func processPacket(json: [String: Any], remoteEndpoint: NWEndpoint) {
        let senderFingerprint = json["fingerprint"] as? String ?? ""
        if senderFingerprint == self.fingerprint {
            return // Bỏ qua gói tin do chính thiết bị này phát
        }

        var ip = "127.0.0.1"
        if case let .hostPort(host, _) = remoteEndpoint {
            switch host {
            case .ipv4(let addr):
                ip = addr.debugDescription
            default:
                break
            }
        }

        let alias = json["alias"] as? String ?? "Thiết bị LocalSend"
        let deviceModel = json["deviceModel"] as? String ?? "Unknown"
        let deviceType = json["deviceType"] as? String ?? "mobile"
        let protocolType = json["protocol"] as? String ?? "http"
        let port = json["port"] as? Int ?? Int(LocalSendProtocol.port)

        let device = Device(
            ip: ip,
            port: port,
            alias: alias,
            deviceModel: deviceModel,
            deviceType: deviceType,
            protocolType: protocolType,
            fingerprint: senderFingerprint
        )

        DispatchQueue.main.async {
            self.onDeviceFound(device)
        }

        // Nếu thiết bị đối phương gửi gói thông báo (announce = true), gửi phản hồi lại để đối phương nhận biết
        if let announce = json["announcement"] as? Bool, announce {
            self.sendAnnouncement(announce: false, targetIP: ip, targetPort: UInt16(port))
        }
    }

    public func sendAnnouncement(announce: Bool = true, targetIP: String = LocalSendProtocol.multicastAddress, targetPort: UInt16 = LocalSendProtocol.port) {
        let payload: [String: Any] = [
            "alias": deviceAlias,
            "version": LocalSendProtocol.protocolVersion,
            "deviceModel": "iPhone",
            "deviceType": "mobile",
            "fingerprint": fingerprint,
            "port": Int(LocalSendProtocol.port),
            "protocol": "http",
            "download": true,
            "announcement": announce
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }

        let host = NWEndpoint.Host(targetIP)
        let port = NWEndpoint.Port(rawValue: targetPort)!
        let connection = NWConnection(host: host, port: port, using: .udp)

        connection.stateUpdateHandler = { state in
            if state == .ready {
                connection.send(content: data, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
        connection.start(queue: .global(qos: .utility))
    }
}
