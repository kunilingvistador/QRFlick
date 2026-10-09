import AppKit
let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
for points in [16,32,128,256,512] { for scale in [1,2] {
 let pixels = points * scale
 let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
 NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
 let transform = NSAffineTransform(); transform.scale(by: CGFloat(pixels)/1024); transform.concat()
 let background = NSBezierPath(roundedRect: NSRect(x:60,y:60,width:904,height:904), xRadius:210,yRadius:210)
 NSGradient(starting: NSColor(srgbRed:0.20,green:0.38,blue:0.98,alpha:1),ending:NSColor(srgbRed:0.08,green:0.18,blue:0.55,alpha:1))!.draw(in:background,angle:-70)
 NSColor.white.setStroke(); let frame = NSBezierPath(); frame.lineWidth=24; frame.lineCapStyle = .round
 for (x,y,dx,dy) in [(CGFloat(240),CGFloat(240),CGFloat(1),CGFloat(1)),(784,240,-1,1),(240,784,1,-1),(784,784,-1,-1)] { frame.move(to:NSPoint(x:x,y:y+dy*100));frame.line(to:NSPoint(x:x,y:y));frame.line(to:NSPoint(x:x+dx*100,y:y)) }; frame.stroke()
 for (x,y) in [(CGFloat(320),CGFloat(560)),(560,560),(320,320)] {
 NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:x,y:y,width:144,height:144),xRadius:20,yRadius:20).fill()
 NSColor(srgbRed:0.13,green:0.27,blue:0.72,alpha:1).setFill();NSBezierPath(roundedRect:NSRect(x:x+30,y:y+30,width:84,height:84),xRadius:8,yRadius:8).fill()
 }
 NSColor.white.setFill();for (x,y) in [(560,320),(620,380),(680,320),(560,440),(680,440)] { NSBezierPath(roundedRect:NSRect(x:x,y:y,width:54,height:54),xRadius:8,yRadius:8).fill() }
 NSGraphicsContext.restoreGraphicsState()
 let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
 try bitmap.representation(using:.png,properties:[:])!.write(to:destination.appendingPathComponent(name))
}}
