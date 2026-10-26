import Foundation

public final class DeviceScanner {
    private let myIP: String
    private let myFingerprint: String
    private let onDeviceFound: (Device) -> Void
    private var isScanning = false

    public init(myIP: String, myFingerprint: String, onDeviceFound: @escaping (Device) -> Void) {
        self.myIP = myIP
        self.myFingerprint = myFingerprint
        self.onDeviceFound = onDeviceFound
    }

    public func scan() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }

        let parts = myIP.components(separatedBy: ".")
        guard parts.count == 4 else { return }
        let subnetPrefix = "\(parts[0]).\(parts[1]).\(parts[2])"

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 1.2
        let probeSession = URLSession(configuration: config)

        await withTaskGroup(of: Void.self) { group in
            for hostNum in 1...254 {
                let targetIP = "\(subnetPrefix).\(hostNum)"
                if targetIP == myIP { continue }

                group.addTask { [weak self] in
                    guard let self = self else { return }
                    await self.probeIP(session: probeSession, ip: targetIP)
                }
            }
        }
    }

    private func probeIP(session: URLSession, ip: String) async {
        guard let url = URL(string: "http://\(ip):\(LocalSendProtocol.port)/api/localsend/v2/info") else { return }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }

            let fingerprint = json["fingerprint"] as? String ?? ""
            if fingerprint == myFingerprint { return }

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
                fingerprint: fingerprint
            )

            await MainActor.run {
                self.onDeviceFound(device)
            }
        } catch {
            // Thiết bị không mở cổng hoặc không chạy LocalSend
        }
    }
}
