import AppKit
let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1200,pixelsHigh:630,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
NSColor(srgbRed:0.97,green:0.98,blue:0.96,alpha:1).setFill();NSBezierPath(rect:NSRect(x:0,y:0,width:1200,height:630)).fill()
let blue=NSColor(srgbRed:0.20,green:0.36,blue:0.91,alpha:1)
("QR Flick" as NSString).draw(at:NSPoint(x:75,y:510),withAttributes:[.font:NSFont.systemFont(ofSize:28,weight:.bold),.foregroundColor:blue])
("QR on your screen?" as NSString).draw(at:NSPoint(x:75,y:345),withAttributes:[.font:NSFont.systemFont(ofSize:59,weight:.semibold),.foregroundColor:NSColor(srgbRed:0.09,green:0.14,blue:0.23,alpha:1)])
("Open it on your Mac." as NSString).draw(at:NSPoint(x:75,y:270),withAttributes:[.font:NSFont.systemFont(ofSize:59,weight:.semibold),.foregroundColor:blue])
("Select the code. Check the address. Open or copy." as NSString).draw(at:NSPoint(x:78,y:180),withAttributes:[.font:NSFont.systemFont(ofSize:23),.foregroundColor:NSColor.darkGray])
("Free · macOS 14+ · Open source" as NSString).draw(at:NSPoint(x:78,y:87),withAttributes:[.font:NSFont.systemFont(ofSize:18),.foregroundColor:NSColor.gray])
if let icon=NSImage(contentsOfFile:CommandLine.arguments[1]) {icon.draw(in:NSRect(x:875,y:235,width:240,height:240))}
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[2]))
