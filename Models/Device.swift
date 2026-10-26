import Foundation

public struct Device: Identifiable, Hashable, Codable {
    public var id: String { "\(ip):\(port)" }
    public let ip: String
    public let port: Int
    public let alias: String
    public let deviceModel: String
    public let deviceType: String
    public let protocolType: String
    public let fingerprint: String
    public var lastSeen: Date

    public init(
        ip: String,
        port: Int = 53317,
        alias: String,
        deviceModel: String = "iPhone",
        deviceType: String = "mobile",
        protocolType: String = "http",
        fingerprint: String = "",
        lastSeen: Date = Date()
    ) {
        self.ip = ip
        self.port = port
        self.alias = alias
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.protocolType = protocolType
        self.fingerprint = fingerprint
        self.lastSeen = lastSeen
    }

    enum CodingKeys: String, CodingKey {
        case ip, port, alias, deviceModel, deviceType
        case protocolType = "protocol"
        case fingerprint
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ip = try container.decodeIfPresent(String.self, forKey: .ip) ?? "127.0.0.1"
        self.port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 53317
        self.alias = try container.decodeIfPresent(String.self, forKey: .alias) ?? "Thiết bị không rõ"
        self.deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel) ?? "Unknown"
        self.deviceType = try container.decodeIfPresent(String.self, forKey: .deviceType) ?? "mobile"
        self.protocolType = try container.decodeIfPresent(String.self, forKey: .protocolType) ?? "http"
        self.fingerprint = try container.decodeIfPresent(String.self, forKey: .fingerprint) ?? ""
        self.lastSeen = Date()
    }
}
