import Foundation
import CoreGraphics

// Restrict browser actions; payload text always remains available for copying.
enum QRPolicy {
    static func webURL(_ text: String) -> URL? {
        guard text == text.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              let components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              let url = components.url else { return nil }
        return url
    }
    static func cropRect(selection: CGRect, bounds: CGRect, width: Int, height: Int) -> CGRect? {
        let area = selection.standardized.intersection(bounds)
        guard !area.isNull, area.width > 4, area.height > 4, bounds.width > 0, bounds.height > 0 else { return nil }
        let sx = CGFloat(width) / bounds.width, sy = CGFloat(height) / bounds.height
        let pixels = CGRect(x: (area.minX - bounds.minX) * sx, y: (bounds.maxY - area.maxY) * sy, width: area.width * sx, height: area.height * sy).integral
        return pixels.intersection(CGRect(x: 0, y: 0, width: width, height: height))
    }
}
