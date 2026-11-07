// Regenerates the layered app icon and Top Shelf images from the logo shapes.
// Usage: swiftc -O scripts/generate-brand-assets.swift -o /tmp/gen && /tmp/gen "labbytv/Assets.xcassets/App Icon & Top Shelf Image.brandassets"
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Polygons measured from splash_and_login_logo.png (600×600, y down).
let lPoly: [CGPoint] = [(221.5,211),(307.5,211),(275,323),(321.5,323),(303,390),(170,390)].map { CGPoint(x: $0.0, y: $0.1) }
let boltPoly: [CGPoint] = [(341.5,211),(412.5,211),(388.5,279.5),(431.5,279.5),(329,390),(353,301),(312.5,301)].map { CGPoint(x: $0.0, y: $0.1) }
let markRect = CGRect(x: 170, y: 211, width: 261.5, height: 179)
let yellow = CGColor(srgbRed: 0xFB/255, green: 0xB4/255, blue: 0x1E/255, alpha: 1)
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func context(_ w: Int, _ h: Int, opaque: Bool) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)   // y down, like the source
    ctx.setShouldAntialias(true); ctx.interpolationQuality = .high
    if opaque { ctx.setFillColor(yellow); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h)) }
    return ctx
}
func fill(_ ctx: CGContext, _ poly: [CGPoint], _ color: CGColor, center: CGPoint, markHeight: CGFloat) {
    let s = markHeight / markRect.height
    let pts = poly.map { CGPoint(x: center.x + ($0.x - markRect.midX) * s, y: center.y + ($0.y - markRect.midY) * s) }
    ctx.setFillColor(color); ctx.addLines(between: pts); ctx.closePath(); ctx.fillPath()
}
func save(_ ctx: CGContext, _ path: String) {
    let img = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil); CGImageDestinationFinalize(dest)
}
let black = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1), white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
let root = CommandLine.arguments[1]

// App icon: Back = yellow, Middle = black L, Front = white bolt (parallax depth on focus).
// Mark kept to ~46% of the height so the parallax crop never clips it.
for (dir, w, h, suffix) in [("App Icon.imagestack", 400, 240, ""), ("App Icon.imagestack", 800, 480, "@2x"), ("App Icon - App Store.imagestack", 1280, 768, "")] {
    let c = CGPoint(x: CGFloat(w) / 2, y: CGFloat(h) / 2), mh = CGFloat(h) * 0.46
    let back = context(w, h, opaque: true); save(back, "\(root)/\(dir)/Back.imagestacklayer/Content.imageset/back\(suffix).png")
    let mid = context(w, h, opaque: false); fill(mid, lPoly, black, center: c, markHeight: mh)
    save(mid, "\(root)/\(dir)/Middle.imagestacklayer/Content.imageset/middle\(suffix).png")
    let front = context(w, h, opaque: false); fill(front, boltPoly, white, center: c, markHeight: mh)
    save(front, "\(root)/\(dir)/Front.imagestacklayer/Content.imageset/front\(suffix).png")
}

// Top Shelf: yellow banner, mark + "LABBY TV" wordmark centred.
func topShelf(_ w: Int, _ h: Int, _ path: String) {
    let ctx = context(w, h, opaque: true)
    let k = CGFloat(h) / 720
    let mh = 230 * k, markW = markRect.width * mh / markRect.height, gap = 56 * k
    let font = NSFont.systemFont(ofSize: 190 * k, weight: .black)
    let text = NSAttributedString(string: "LABBY TV", attributes: [.font: font, .foregroundColor: NSColor.black, .kern: 4 * k])
    let line = CTLineCreateWithAttributedString(text)
    let tw = CTLineGetTypographicBounds(line, nil, nil, nil)
    let total = markW + gap + tw, x0 = (CGFloat(w) - total) / 2
    let c = CGPoint(x: x0 + markW / 2, y: CGFloat(h) / 2)
    fill(ctx, lPoly, black, center: c, markHeight: mh); fill(ctx, boltPoly, white, center: c, markHeight: mh)
    // Text draws in the unflipped space.
    ctx.saveGState(); ctx.scaleBy(x: 1, y: -1); ctx.translateBy(x: 0, y: -CGFloat(h))
    let capH = font.capHeight
    ctx.textPosition = CGPoint(x: x0 + markW + gap, y: CGFloat(h) / 2 - capH / 2)
    CTLineDraw(line, ctx); ctx.restoreGState()
    save(ctx, path)
}
topShelf(1920, 720, "\(root)/Top Shelf Image.imageset/topshelf.png")
topShelf(3840, 1440, "\(root)/Top Shelf Image.imageset/topshelf@2x.png")
topShelf(2320, 720, "\(root)/Top Shelf Image Wide.imageset/topshelf_wide.png")
topShelf(4640, 1440, "\(root)/Top Shelf Image Wide.imageset/topshelf_wide@2x.png")
print("done")
