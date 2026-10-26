import Foundation

public enum SendResult {
    case success
    case declined
    case error(String)
}

public final class ClientSender {
    private let senderAlias: String
    private let senderFingerprint: String
    private let session: URLSession

    public init(senderAlias: String, senderFingerprint: String) {
        self.senderAlias = senderAlias
        self.senderFingerprint = senderFingerprint

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    /// Gửi văn bản / tin nhắn trực tiếp tới thiết bị đối phương
    public func sendText(device: Device, text: String) async -> SendResult {
        let fileId = UUID().uuidString
        let textData = text.data(using: .utf8) ?? Data()

        return await sendFilePayload(
            device: device,
            fileId: fileId,
            fileName: "text_\(Int(Date().timeIntervalSince1970)).txt",
            fileData: textData,
            fileType: "text/plain"
        )
    }

    /// Gửi tệp tin từ URL lưu trên máy iOS
    public func sendFile(device: Device, fileURL: URL) async -> SendResult {
        guard let data = try? Data(contentsOf: fileURL) else {
            return .error("Không thể đọc tệp tin từ máy")
        }

        let fileId = UUID().uuidString
        let fileName = fileURL.lastPathComponent

        return await sendFilePayload(
            device: device,
            fileId: fileId,
            fileName: fileName,
            fileData: data,
            fileType: "*/*"
        )
    }

    private func sendFilePayload(
        device: Device,
        fileId: String,
        fileName: String,
        fileData: Data,
        fileType: String
    ) async -> SendResult {
        let scheme = device.protocolType.isEmpty ? "http" : device.protocolType
        let prepareUrlString = "\(scheme)://\(device.ip):\(device.port)/api/localsend/v2/prepare-upload"

        guard let prepareUrl = URL(string: prepareUrlString) else {
            return .error("URL thiết bị không hợp lệ")
        }

        // 1. Giai đoạn Handshake (prepare-upload)
        let prepareBody: [String: Any] = [
            "info": [
                "alias": senderAlias,
                "version": LocalSendProtocol.protocolVersion,
                "deviceModel": "iPhone",
                "deviceType": "mobile",
                "fingerprint": senderFingerprint,
                "port": Int(LocalSendProtocol.port),
                "protocol": "http",
                "download": true
            ],
            "files": [
                fileId: [
                    "id": fileId,
                    "fileName": fileName,
                    "size": fileData.count,
                    "fileType": fileType
                ]
            ]
        ]

        var request = URLRequest(url: prepareUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: prepareBody)

        do {
            let (responseData, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("Phản hồi không hợp lệ từ thiết bị nhận")
            }

            if httpResponse.statusCode == 403 {
                return .declined
            }

            guard httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let sessionId = json["sessionId"] as? String,
                  let filesObj = json["files"] as? [String: String],
                  let token = filesObj[fileId] else {
                return .error("Thiết bị từ chối hoặc giao thức handshake thất bại")
            }

            // 2. Giai đoạn Upload (Tải tệp lên)
            let uploadUrlString = "\(scheme)://\(device.ip):\(device.port)/api/localsend/v2/upload?sessionId=\(sessionId)&fileId=\(fileId)&token=\(token)"
            guard let uploadUrl = URL(string: uploadUrlString) else {
                return .error("URL tải lên không hợp lệ")
            }

            var uploadRequest = URLRequest(url: uploadUrl)
            uploadRequest.httpMethod = "POST"
            uploadRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            uploadRequest.httpBody = fileData

            let (_, uploadResponse) = try await session.data(for: uploadRequest)
            guard let uploadHttp = uploadResponse as? HTTPURLResponse, uploadHttp.statusCode == 200 else {
                return .error("Lỗi trong quá trình truyền dữ liệu")
            }

            return .success
        } catch {
            return .error(error.localizedDescription)
        }
    }
}
