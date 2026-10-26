import Foundation
import Network

public struct SharedFileMetadata {
    public let url: URL
    public let fileName: String
    public let fileSize: Int64

    public init(url: URL, fileName: String, fileSize: Int64) {
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
    }
}

public final class LocalHttpServer {
    private var listener: NWListener?
    private var isRunning = false
    private let deviceAlias: String
    private let fingerprint: String
    private let port: UInt16
    private let getSharedFile: () -> SharedFileMetadata?
    private let onDeviceRegistered: (Device) -> Void
    private let onFileReceived: (TransferItem, URL) -> Void
    private let onTextReceived: (String, String) -> Void

    private var activeSessions: [String: [String: String]] = [:]

    public init(
        deviceAlias: String,
        fingerprint: String,
        port: UInt16 = LocalSendProtocol.port,
        getSharedFile: @escaping () -> SharedFileMetadata?,
        onDeviceRegistered: @escaping (Device) -> Void,
        onFileReceived: @escaping (TransferItem, URL) -> Void,
        onTextReceived: @escaping (String, String) -> Void
    ) {
        self.deviceAlias = deviceAlias
        self.fingerprint = fingerprint
        self.port = port
        self.getSharedFile = getSharedFile
        self.onDeviceRegistered = onDeviceRegistered
        self.onFileReceived = onFileReceived
        self.onTextReceived = onTextReceived
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        do {
            let tcpParams = NWParameters.tcp
            let endpoint = NWEndpoint.Port(rawValue: port)!
            listener = try NWListener(using: tcpParams, on: endpoint)

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleHttpConnection(connection)
            }

            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("[LocalHttpServer] HTTP Server lắng nghe trên cổng \(self.port)")
                case .failed(let error):
                    print("[LocalHttpServer] Lỗi server: \(error)")
                default:
                    break
                }
            }

            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("[LocalHttpServer] Không thể khởi động server: \(error)")
        }
    }

    public func stop() {
        isRunning = false
        listener?.cancel()
        listener = nil
    }

    private func handleHttpConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        readCompleteRequest(connection: connection, accumulatedData: Data())
    }

    private func readCompleteRequest(connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isComplete, error) in
            guard let self = self else { return }
            var currentData = accumulatedData
            if let data = data {
                currentData.append(data)
            }

            if self.isHttpRequestComplete(currentData) || isComplete || error != nil {
                self.processHttpRequest(connection: connection, data: currentData)
            } else {
                self.readCompleteRequest(connection: connection, accumulatedData: currentData)
            }
        }
    }

    private func isHttpRequestComplete(_ data: Data) -> Bool {
        guard let headerString = String(data: data.prefix(4096), encoding: .utf8) else { return false }
        guard let headerEndRange = headerString.range(of: "\r\n\r\n") else { return false }

        // Kiểm tra Content-Length
        for line in headerString.components(separatedBy: "\r\n") {
            if line.lowercased().starts(with: "content-length:") {
                let lengthStr = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0"
                if let length = Int(lengthStr) {
                    let headerLength = headerString[..<headerEndRange.upperBound].utf8.count
                    return data.count >= (headerLength + length)
                }
            }
        }
        return true
    }

    private func processHttpRequest(connection: NWConnection, data: Data) {
        guard let rawString = String(data: data.prefix(4096), encoding: .utf8) else {
            connection.cancel()
            return
        }

        let lines = rawString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            connection.cancel()
            return
        }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            connection.cancel()
            return
        }

        let method = parts[0].uppercased()
        let pathWithQuery = parts[1]
        let path = pathWithQuery.components(separatedBy: "?").first ?? pathWithQuery

        // Lấy phần Body (sau \r\n\r\n)
        var bodyData = Data()
        if let range = data.range(of: Data([13, 10, 13, 10])) {
            bodyData = data.subdata(in: range.upperBound..<data.count)
        }

        switch (method, path) {
        case ("GET", "/api/localsend/v2/info"):
            handleGetInfo(connection: connection)

        case ("POST", "/api/localsend/v2/register"):
            handleRegister(connection: connection, body: bodyData)

        case ("POST", "/api/localsend/v2/prepare-upload"):
            handlePrepareUpload(connection: connection, body: bodyData)

        case ("POST", "/api/localsend/v2/upload"):
            handleUpload(connection: connection, pathWithQuery: pathWithQuery, body: bodyData)

        case ("GET", "/api/localsend/v2/download"):
            handleDownload(connection: connection)

        case ("GET", "/"):
            handleWebShareUI(connection: connection)

        default:
            sendJsonResponse(connection: connection, statusCode: 404, json: ["error": "Not Found"])
        }
    }

    private func handleGetInfo(connection: NWConnection) {
        let response: [String: Any] = [
            "alias": deviceAlias,
            "version": LocalSendProtocol.protocolVersion,
            "deviceModel": "iPhone",
            "deviceType": "mobile",
            "fingerprint": fingerprint,
            "port": Int(port),
            "protocol": "http",
            "download": true
        ]
        sendJsonResponse(connection: connection, statusCode: 200, json: response)
    }

    private func handleRegister(connection: NWConnection, body: Data) {
        if let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            let alias = json["alias"] as? String ?? "Thiết bị LocalSend"
            let ip = (connection.endpoint as? NWEndpoint)?.debugDescription ?? "127.0.0.1"
            let device = Device(
                ip: ip,
                port: json["port"] as? Int ?? Int(port),
                alias: alias,
                deviceModel: json["deviceModel"] as? String ?? "Unknown",
                deviceType: json["deviceType"] as? String ?? "mobile",
                protocolType: json["protocol"] as? String ?? "http",
                fingerprint: json["fingerprint"] as? String ?? ""
            )
            DispatchQueue.main.async {
                self.onDeviceRegistered(device)
            }
        }
        sendJsonResponse(connection: connection, statusCode: 200, json: [:])
    }

    private func handlePrepareUpload(connection: NWConnection, body: Data) {
        let sessionId = UUID().uuidString
        var fileTokens: [String: String] = [:]

        if let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let files = json["files"] as? [String: [String: Any]] {
            for (fileId, _) in files {
                fileTokens[fileId] = UUID().uuidString
            }
        }

        activeSessions[sessionId] = fileTokens
        let response: [String: Any] = [
            "sessionId": sessionId,
            "files": fileTokens
        ]
        sendJsonResponse(connection: connection, statusCode: 200, json: response)
    }

    private func handleUpload(connection: NWConnection, pathWithQuery: String, body: Data) {
        let queryParams = parseQueryString(pathWithQuery)
        let fileId = queryParams["fileId"] ?? "file_\(Int(Date().timeIntervalSince1970))"

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localSendDir = documentsURL.appendingPathComponent("LocalSend", isDirectory: true)
        try? FileManager.default.createDirectory(at: localSendDir, withIntermediateDirectories: true)

        let targetURL = localSendDir.appendingPathComponent("received_\(fileId)")
        try? body.write(to: targetURL)

        let item = TransferItem(
            name: "Tệp nhận: \(fileId)",
            size: Int64(body.count),
            senderOrReceiver: "Thiết bị gửi",
            isIncoming: true,
            status = "Hoàn tất",
            fileURL: targetURL
        )

        DispatchQueue.main.async {
            self.onFileReceived(item, targetURL)
        }

        sendJsonResponse(connection: connection, statusCode: 200, json: ["status": "ok"])
    }

    private func handleDownload(connection: NWConnection) {
        guard let shared = getSharedFile() else {
            sendJsonResponse(connection: connection, statusCode: 404, json: ["error": "No file shared"])
            return
        }

        guard let fileData = try? Data(contentsOf: shared.url) else {
            sendJsonResponse(connection: connection, statusCode: 500, json: ["error": "Cannot read file"])
            return
        }

        let headers = [
            "HTTP/1.1 200 OK",
            "Content-Type: application/octet-stream",
            "Content-Disposition: attachment; filename=\"\(shared.fileName)\"",
            "Content-Length: \(fileData.count)",
            "Connection: close",
            "\r\n"
        ].joined(separator: "\r\n")

        var responseData = headers.data(using: .utf8)!
        responseData.append(fileData)

        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func handleWebShareUI(connection: NWConnection) {
        let shared = getSharedFile()
        let sharedSection: String
        if let file = shared {
            sharedSection = """
            <div class="card">
                <h3>📦 Tệp sẵn sàng tải về</h3>
                <p><b>\(file.fileName)</b> (\(ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file)))</p>
                <a href="/api/localsend/v2/download" class="button">📥 Tải tệp về máy</a>
            </div>
            """
        } else {
            sharedSection = """
            <div class="card">
                <p>Hiện tại chưa có tệp nào được chọn để chia sẻ từ iPhone.</p>
            </div>
            """
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>LocalSend iOS Web Share</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #0f172a; margin: 0; padding: 20px; }
                .container { max-width: 480px; margin: 40px auto; background: white; border-radius: 20px; padding: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.06); }
                h1 { color: #0d9488; font-size: 24px; margin-top: 0; display: flex; align-items: center; gap: 8px; }
                .card { background: #f0fdfa; border: 1px solid #ccfbf1; border-radius: 14px; padding: 16px; margin: 16px 0; }
                .button { display: inline-block; background: #0d9488; color: white; text-decoration: none; padding: 12px 24px; border-radius: 12px; font-weight: bold; margin-top: 10px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📲 LocalSend iOS</h1>
                <p>Chia sẻ tệp ngang hàng trực tiếp qua Wi-Fi nội bộ.</p>
                \(sharedSection)
            </div>
        </body>
        </html>
        """

        let response = [
            "HTTP/1.1 200 OK",
            "Content-Type: text/html; charset=utf-8",
            "Content-Length: \(html.utf8.count)",
            "Connection: close",
            "\r\n"
        ].joined(separator: "\r\n") + html

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendJsonResponse(connection: NWConnection, statusCode: Int, json: [String: Any]) {
        let jsonData = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        let statusText = statusCode == 200 ? "OK" : "Error"
        let response = [
            "HTTP/1.1 \(statusCode) \(statusText)",
            "Content-Type: application/json; charset=utf-8",
            "Content-Length: \(jsonData.count)",
            "Access-Control-Allow-Origin: *",
            "Connection: close",
            "\r\n"
        ].joined(separator: "\r\n")

        var fullData = response.data(using: .utf8)!
        fullData.append(jsonData)

        connection.send(content: fullData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func parseQueryString(_ path: String) -> [String: String] {
        var params: [String: String] = [:]
        guard let queryString = path.components(separatedBy: "?").last else { return params }
        for pair in queryString.components(separatedBy: "&") {
            let kv = pair.components(separatedBy: "=")
            if kv.count == 2 {
                params[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
            }
        }
        return params
    }
}
