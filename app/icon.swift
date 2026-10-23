// Vẽ icon 1024x1024: squircle gradient + monogram "T" + 3 chấm trạng thái agent
import AppKit
let S: CGFloat = 1024
func shadow(_ a: CGFloat, _ blur: CGFloat, _ dy: CGFloat) -> NSShadow {
  let s = NSShadow(); s.shadowColor = NSColor.black.withAlphaComponent(a); s.shadowBlurRadius = blur
  s.shadowOffset = NSSize(width: 0, height: dy); return s
}
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
// khung icon chuẩn macOS: 824px, bo góc ~185
let r = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: r, xRadius: 185, yRadius: 185)
ctx.saveGState()
shadow(0.35, 28, -12).set()
NSColor.black.setFill(); shape.fill()
ctx.restoreGState()
shape.addClip()
NSGradient(colors: [NSColor(srgbRed: 0.98, green: 0.47, blue: 0.30, alpha: 1),
                    NSColor(srgbRed: 0.80, green: 0.25, blue: 0.45, alpha: 1),
                    NSColor(srgbRed: 0.23, green: 0.15, blue: 0.45, alpha: 1)])!.draw(in: r, angle: -55)
// bóng sáng nhẹ từ trên xuống
NSGradient(colors: [NSColor.white.withAlphaComponent(0.18), NSColor.white.withAlphaComponent(0)])!.draw(in: r, angle: -90)
// monogram
let para = NSMutableParagraphStyle(); para.alignment = .center
let font = NSFont.systemFont(ofSize: 560, weight: .heavy)
let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white, .paragraphStyle: para,
  .shadow: shadow(0.25, 18, -8)]
NSAttributedString(string: "T", attributes: attr).draw(in: NSRect(x: 100, y: 250, width: 824, height: 680))
// 3 chấm agent: chờ / xong / đang chạy
let dots: [NSColor] = [NSColor(srgbRed: 1, green: 0.72, blue: 0.2, alpha: 1),
                       NSColor(srgbRed: 0.35, green: 0.9, blue: 0.55, alpha: 1),
                       NSColor(srgbRed: 0.45, green: 0.75, blue: 1, alpha: 1)]
for (i, c) in dots.enumerated() {
  let d: CGFloat = 92, gap: CGFloat = 42
  let x = S / 2 - (3 * d + 2 * gap) / 2 + CGFloat(i) * (d + gap)
  let o = NSBezierPath(ovalIn: NSRect(x: x, y: 190, width: d, height: d))
  NSColor.white.withAlphaComponent(0.95).setFill(); NSBezierPath(ovalIn: NSRect(x: x - 9, y: 181, width: d + 18, height: d + 18)).fill()
  c.setFill(); o.fill()
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
