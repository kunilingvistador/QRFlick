import AppKit
import CoreImage
import Vision
func qr(_ text: String) -> CIImage {
    let filter = CIFilter(name: "CIQRCodeGenerator")!; filter.setValue(Data(text.utf8), forKey: "inputMessage"); filter.setValue("M", forKey: "inputCorrectionLevel")
    return filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
}
let context = CIContext(options: [.useSoftwareRenderer: true])
func decode(_ image: CIImage) throws -> Set<String> {
    let request = VNDetectBarcodesRequest(); request.symbologies = [.qr]
    try VNImageRequestHandler(cgImage: context.createCGImage(image.transformed(by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY)), from: image.extent.offsetBy(dx: -image.extent.minX, dy: -image.extent.minY))!).perform([request])
    return Set((request.results ?? []).compactMap(\.payloadStringValue))
}
for text in ["https://example.com/path?q=hello", "Привет, мир", "WIFI:T:WPA;S:Example;P:password;;", "mailto:hello@example.com"] {
    let code = qr(text); let background = CIImage(color: .white).cropped(to: code.extent.insetBy(dx: -32, dy: -32))
    precondition(try! decode(code.composited(over: background)) == [text]); print("PASS payload: \(text.prefix(25))")
}
let a = qr("https://example.com/a"), b = qr("https://example.com/b").transformed(by: CGAffineTransform(translationX: 400, y: 0))
let base = CIImage(color: .white).cropped(to: CGRect(x: -32, y: -32, width: 800, height: 400))
precondition(try! decode(a.composited(over: b.composited(over: base))) == ["https://example.com/a", "https://example.com/b"]); print("PASS multiple QR")
precondition(try! decode(base).isEmpty); print("PASS no QR")
let fixture = qr("https://example.com/screenqr-test")
let padded = fixture.composited(over: CIImage(color: .white).cropped(to: fixture.extent.insetBy(dx: -32, dy: -32)))
let cg = context.createCGImage(padded, from: padded.extent)!
let bitmap = NSBitmapImageRep(cgImage: cg)
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "/tmp/screenqr-fixture.png"))
let multiple = a.composited(over: b.composited(over: base))
let multiCG = context.createCGImage(multiple, from: multiple.extent)!
try NSBitmapImageRep(cgImage: multiCG).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "/tmp/screenqr-multiple.png"))
