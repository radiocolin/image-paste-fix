import AppKit
import CommonCrypto

final class PasteboardMonitor {

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastWrittenHash: String?

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Detection

    private func check() {
        let pb = NSPasteboard.general
        let currentCount = pb.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        let contentHash = hashPasteboard(pb)
        if contentHash == lastWrittenHash { return }

        guard shouldTrigger(pb) else { return }
        guard let html = pb.string(forType: .html) else { return }
        guard let imageURL = extractImageURL(from: html) else { return }

        downloadAndRewrite(imageURL: imageURL)
    }

    private func shouldTrigger(_ pb: NSPasteboard) -> Bool {
        let types = pb.types ?? []

        guard types.contains(.URL) else { return false }
        if !hasGoogleURL(pb) { return false }
        guard types.contains(.html) else { return false }

        guard let html = pb.string(forType: .html),
              htmlHasAnchorWrappingImage(html) else { return false }

        let hasTIFF = types.contains(.tiff)
        let hasPNG = types.contains(.png)

        if hasPNG, let pngData = pb.data(forType: .png) {
            if pngIsURLString(pngData) { return true }
        }

        if hasTIFF { return true }

        return false
    }

    private func hasGoogleURL(_ pb: NSPasteboard) -> Bool {
        if let urlString = pb.string(forType: .string) ?? pb.propertyList(forType: .URL) as? String,
           let url = URL(string: urlString),
           let host = url.host,
           host.contains("google.") {
            return true
        }
        if let items = pb.pasteboardItems {
            return items.contains { item in
                if let urlStr = item.string(forType: .init("public.url")),
                   let url = URL(string: urlStr),
                   let host = url.host,
                   host.contains("google.") {
                    return true
                }
                return false
            }
        }
        return false
    }

    // MARK: - HTML Parsing

    private func htmlHasAnchorWrappingImage(_ html: String) -> Bool {
        let pattern = #"<a\s[^>]*>[\s\S]*?<img\s"#
        return html.range(of: pattern, options: .regularExpression) != nil
    }

    func extractImageURL(from html: String) -> URL? {
        let pattern = #"<img\s[^>]*src\s*=\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard let srcRange = Range(match.range(at: 1), in: html) else { continue }
            let src = String(html[srcRange])
                .replacingOccurrences(of: "&amp;", with: "&")

            if src.contains("gstatic.com") { continue }
            if src.hasPrefix("data:") { continue }
            guard let url = URL(string: src), url.scheme == "http" || url.scheme == "https" else { continue }

            return url
        }
        return nil
    }

    // MARK: - PNG / URL detection

    private func pngIsURLString(_ data: Data) -> Bool {
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        if data.count >= 8 {
            let header = [UInt8](data.prefix(8))
            if header == pngSignature { return false }
        }
        if let str = String(data: data, encoding: .utf8), str.hasPrefix("http") {
            return true
        }
        return false
    }

    // MARK: - Download & Rewrite

    private func downloadAndRewrite(imageURL: URL) {
        let task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            guard let self, let data, error == nil else { return }

            guard let mimeType = (response as? HTTPURLResponse)?.mimeType,
                  mimeType.hasPrefix("image/") else { return }

            guard let bitmapRep = NSBitmapImageRep(data: data) else { return }
            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return }
            let tiffData = bitmapRep.tiffRepresentation

            DispatchQueue.main.async {
                self.writeToPasteboard(pngData: pngData, tiffData: tiffData)
            }
        }
        task.resume()
    }

    private func writeToPasteboard(pngData: Data, tiffData: Data?) {
        let pb = NSPasteboard.general
        var types: [NSPasteboard.PasteboardType] = [.png]
        if tiffData != nil { types.append(.tiff) }

        pb.clearContents()
        pb.declareTypes(types, owner: nil)
        pb.setData(pngData, forType: .png)
        if let tiffData { pb.setData(tiffData, forType: .tiff) }

        lastChangeCount = pb.changeCount
        lastWrittenHash = hashPasteboard(pb)
    }

    // MARK: - Hashing

    private func hashPasteboard(_ pb: NSPasteboard) -> String {
        var hasher = CC_SHA256_CTX()
        CC_SHA256_Init(&hasher)
        if let types = pb.types {
            for type in types {
                if let data = pb.data(forType: type) {
                    data.withUnsafeBytes { buffer in
                        _ = CC_SHA256_Update(&hasher, buffer.baseAddress, CC_LONG(buffer.count))
                    }
                }
            }
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &hasher)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
