import Foundation
import AppKit
import CoreImage
// Reads an image file, averages its TOP strip (menu-bar region), prints darkness 0(white)..100(black).
let a = CommandLine.arguments
guard a.count > 1, let img = CIImage(contentsOf: URL(fileURLWithPath: a[1])) else { print("ERR"); exit(1) }
let e = img.extent
let stripH = max(CGFloat(24), e.height * 0.02)
let rect = CGRect(x: e.origin.x, y: e.maxY - stripH, width: e.width, height: stripH) // CIImage y is up → top strip
let ctx = CIContext(options: [.workingColorSpace: NSNull()])
let f = CIFilter(name: "CIAreaAverage")!
f.setValue(img, forKey: kCIInputImageKey)
f.setValue(CIVector(cgRect: rect), forKey: kCIInputExtentKey)
guard let out = f.outputImage else { print("ERR2"); exit(1) }
var px = [UInt8](repeating: 0, count: 4)
ctx.render(out, toBitmap: &px, rowBytes: 4, bounds: CGRect(x:0,y:0,width:1,height:1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
let r = Double(px[0])/255, g = Double(px[1])/255, b = Double(px[2])/255
let lum = 0.2126*r + 0.7152*g + 0.0722*b
print(Int((1.0 - lum)*100 + 0.5))
