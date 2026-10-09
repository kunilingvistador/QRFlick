import Foundation
import CoreGraphics
let permitted = ["https://example.com/a?q=hello#part", "HTTP://example.com", "https://пример.рф/путь"]
let rejected = ["javascript:alert(1)", "file:///tmp/a", "mailto:a@example.com", "hello", " https://example.com", "https://", "https://user:password@example.com", "https://example.com\n", "https://example.com/\u{0000}"]
for text in permitted { precondition(QRPolicy.webURL(text) != nil, text) }
for text in rejected { precondition(QRPolicy.webURL(text) == nil, text) }
let bounds = CGRect(x:0,y:0,width:1000,height:800)
precondition(QRPolicy.cropRect(selection:CGRect(x:100,y:200,width:300,height:100),bounds:bounds,width:2000,height:1600) == CGRect(x:200,y:1000,width:600,height:200))
precondition(QRPolicy.cropRect(selection:CGRect(x:400,y:300,width:-300,height:-100),bounds:bounds,width:2000,height:1600) == CGRect(x:200,y:1000,width:600,height:200))
precondition(QRPolicy.cropRect(selection:CGRect(x:-50,y:750,width:100,height:100),bounds:bounds,width:1000,height:800) == CGRect(x:0,y:0,width:50,height:50))
precondition(QRPolicy.cropRect(selection:CGRect(x:1,y:1,width:3,height:3),bounds:bounds,width:1000,height:800) == nil)
precondition(QRPolicy.cropRect(selection:CGRect(x:2000,y:2000,width:100,height:100),bounds:bounds,width:1000,height:800) == nil)
print("PASS 12 URL policies and 5 screen geometry cases")
