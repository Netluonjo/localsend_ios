import Foundation

public struct TransferItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let size: Int64
    public let senderOrReceiver: String
    public let isIncoming: BooleanLiteralType
    public let status: String
    public let timestamp: Date
    public let fileURL: URL?

    public init(
        id: String = UUID().uuidString,
        name: String,
        size: Int64,
        senderOrReceiver: String,
        isIncoming: Bool,
        status: String = "Hoàn tất",
        timestamp: Date = Date(),
        fileURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.senderOrReceiver = senderOrReceiver
        self.isIncoming = isIncoming
        self.status = status
        self.timestamp = timestamp
        self.fileURL = fileURL
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm • dd/MM"
        return formatter.string(from: timestamp)
    }
}
