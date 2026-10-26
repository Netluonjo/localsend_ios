import Foundation

public struct LocalSendProtocol {
    public static let port: UInt16 = 53317
    public static let multicastAddress = "224.0.0.167"
    public static let protocolVersion = "2.0"

    public static var certificateFingerprint: String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    /// Lấy địa chỉ IP Wi-Fi nội bộ của thiết bị iOS (thường là giao diện en0)
    public static func getLocalIPAddress() -> String {
        var address = "127.0.0.1"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return address
        }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            // Chỉ lấy IPv4 (AF_INET), trạng thái UP và không phải loopback (IFF_LOOPBACK)
            if addr.sa_family == UInt8(AF_INET) {
                if (flags & (IFF_UP | IFF_RUNNING)) != 0 && (flags & IFF_LOOPBACK) == 0 {
                    let name = String(cString: ptr.pointee.ifa_name)
                    // Trên iOS, en0 là kết nối Wi-Fi chính
                    if name == "en0" || name.starts(with: "en") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(
                            ptr.pointee.ifa_addr,
                            socklen_t(addr.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        ) == 0 {
                            address = String(cString: hostname)
                            break
                        }
                    }
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }
}
